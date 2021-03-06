(:
 : MVC Core Functions
 :
 : Copyright (c) 2010 Nuno Job [nunojob.com].
 : All Rights Reserved.
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : The use of the Apache License does not indicate that this project is
 : affiliated with the Apache Software Foundation.
 :)
xquery version "1.0-ml" ;

module  namespace mvc   = "http://ns.dscape.org/2010/dxc/mvc" ;

declare namespace error = "http://marklogic.com/xdmp/error" ;

import module
  namespace gen = "http://ns.dscape.org/2010/dxc/func/gen-tree"
  at "../func/gen-tree.xqy";
import module
  namespace h   = "http://ns.dscape.org/2010/dxc/http"
  at "../http/http.xqy";
import module
  namespace s   = "http://ns.dscape.org/2010/dxc/string"
  at "../string/string.xqy";
import module
  namespace seq = "http://ns.dscape.org/2010/dxc/sequence"
  at "../sequence/sequence.xqy";
import module
  namespace date = "http://ns.dscape.org/2010/dxc/date"
  at "../date/date.xqy";
import module
  namespace u = "http://ns.dscape.org/2010/dxc/ext/util"
  at "../ext/util.xqy" ;

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ vars ~~ :)
declare variable $controller-directory    := "/ctr/" ;
declare variable $model-directory         := "/mdl/" ;
declare variable $view-directory          := "/view/" ;
declare variable $template-directory      := "/layout/" ;
declare variable $dxc-directory           := "/lib/dxc/" ;
declare variable $pub-directory           := "/pub/" ;
declare variable $invoke-path             := 
  fn:concat( $dxc-directory, "invoke/invoke.xqy" ) ;
declare variable $path-404                := 
  fn:concat( $pub-directory, "404.xqy" ) ;
declare variable $supported-verbs         :=
  ( "GET", "POST", "PUT", "DELETE", "HEAD") ;
declare variable $supported-content-types :=
  ( "text/plain", "text/html", "application/xml" ) ; (: order matters :)
declare variable $default-content-type    := "text/plain" ;
declare variable $default-error-id        := 'dxc_internal' ;

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ accessors ~~ :)
declare function mvc:controller-directory()    { $controller-directory } ;
declare function mvc:model-directory()         { $controller-directory } ;
declare function mvc:template-directory()      { $template-directory } ;
declare function mvc:view-directory()          { $view-directory } ;
declare function mvc:dxc-directory()           { $dxc-directory } ;
declare function mvc:pub-directory()           { $pub-directory } ;
declare function mvc:invoke-path()             { $invoke-path } ;
declare function mvc:path-404()                { $path-404 } ;
declare function mvc:supported-verbs()         { $supported-verbs } ;
declare function mvc:supported-content-types() { $supported-content-types } ;
declare function mvc:default-content-type()    { $default-content-type } ;
declare function mvc:controller-action-path( $controller, $action ) {
  fn:concat( mvc:controller-directory(), 
    fn:replace($controller, ':', ''), ".xqy?_action=", $action ) };
declare function mvc:view-path( $controller, $view, $format ){
  mvc:q( "$1$2/$3.$4.xqy", 
       ( mvc:view-directory(), $controller, $view, $format ) ) };
declare function mvc:template-path( $template, $format ){
  mvc:q( "$1$2.$3.xqy", 
       ( mvc:template-directory(), $template, $format ) ) };

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ content-type ~~ :)
declare function mvc:negotiate-content-type() {
  h:negotiate-content-type( xdmp:get-request-header( "Accept" ), 
    mvc:supported-content-types(), mvc:default-content-type() ) } ;

declare function mvc:extension-for-content-type( $content-type ) {
  if ( $content-type = "text/plain" )
  then "txt"
  else if ( $content-type = "text/html")
  then "html" else "xml" };

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ http accessors ~~ :)
declare function mvc:action() { mvc:get-input('action') } ;
declare function mvc:id() { mvc:get-input('id') } ;
declare function mvc:controller() { mvc:get-input('controller') } ;

declare function mvc:get-input( $name ) {
  xdmp:get-request-field( fn:concat('_', $name) ) };
declare function mvc:get-field( $name ) { mvc:get-field( $name, "") };
declare function mvc:get-field( $name, $default ) { 
  xdmp:get-request-field( $name, $default ) };

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ redirects ~~ :)
declare function mvc:redirect-to-controller() {
  xdmp:invoke( fn:concat( mvc:controller-directory(), 
    mvc:controller(), ".xqy") ) } ;

declare function mvc:redirect-response() {
  let $url := mvc:get-input( "url" )
  return if ( $url )
         then mvc:redirect-response( xdmp:url-decode( $url ) )
         else mvc:raise-error( 'No URL was specified', 404, "Not Found" ) } ;

declare function mvc:redirect-response( $url ) {
  xdmp:redirect-response( $ url ) } ;

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ headers ~~ :)
declare function mvc:must-revalidate-cache() { h:must-revalidate-cache() } ;
declare function mvc:no-cache() { h:no-cache() } ;
declare function mvc:etag ( $id ) { h:etag( $id ) };
declare function mvc:weak-etag ( $id ) { h:weak-etag( $id ) };

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ aux ~~ :)
declare function mvc:function() {
  mvc:function(
    fn:lower-case(
      ( mvc:get-input('action'), xdmp:get-request-method() ) [ . != "" ] [1]))};

declare function mvc:function( $name ) {
  xdmp:function( xs:QName( fn:concat( "local:", $name ) ) ) } ;

declare function mvc:tree-from-request-fields() {
  let $keys   := xdmp:get-request-field-names() [fn:starts-with(., "/")]
  let $values := for $k in $keys return xdmp:get-request-field($k)
  return gen:process-fields( $keys, $values ) } ;

declare function mvc:view-map( $view-path, $args ) { 
    let $view            := mvc:document-get($view-path)
    let $args_           := seq:from-seq( $args )
    let $functions_      := seq:from-seq( u:local-functions( $view ) )  
    let $xquery          := fn:concat(
        'xquery version "1.0-ml" ; import module namespace mvc = 
         "http://ns.dscape.org/2010/dxc/mvc" at "/lib/dxc/mvc/mvc.xqy"; import 
         module namespace seq = "http://ns.dscape.org/2010/dxc/sequence" at 
         "/lib/dxc/sequence/sequence.xqy"; declare variable $args_ external; 
         declare variable $functions_ external; declare variable $args := 
         seq:to-seq( $args_ ); declare variable $functions := 
         seq:to-seq( $functions_ ); ',$view,' mvc:sequence-to-map( for $f in 
         $functions return ( $f, seq:from-seq( xdmp:apply( 
         mvc:function( $f ) ) ) ) )'
      ) return xdmp:eval( $xquery,
        (xs:QName("args_"), $args_, xs:QName("functions_"), $functions_)) } ;

declare function mvc:best-available-view() {
  mvc:raise-error( 'View not supported yet.', 404, 'Not Found' )
  (: later - what to do when a view is not available or maybe another exception
     try find another view and render it, if not 
     then just render error saying
     how do we separate this exception from others, and prevent infinite loops?
     next, not today :) } ;

declare function mvc:sequence-to-map( $sequence ) {
 seq:sequence-to-map( $sequence ) } ;

declare function mvc:q( $str, $opts ) { s:q( $str,$opts ) };
declare function mvc:document-get( $path ) { u:document-get($path) } ;

declare function mvc:log( $msg ) { mvc:log( $msg, "info" ) };
declare function mvc:log($msg, $level) {
  let $l := for $e in $msg return fn:concat("DXC-MVC => ", $e)
  return xdmp:log( $l, $level ) };

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ render ~~ :)
declare function mvc:render( $resource, $view ) { mvc:render( $resource, $view, () ) } ;

declare function mvc:render( $resource, $view, $args ) {
  mvc:render( $resource, $view, $args, 200, 'OK', 'default' ) } ;

declare function mvc:render( $resource, 
    $view, $args, $http-code, $http-msg, $template ) {
try {
  let $content-type    := mvc:negotiate-content-type()
    let $_ := xdmp:set-response-content-type( $content-type )
    let $_ := xdmp:set-response-code( $http-code, $http-msg )
    let $_ := xdmp:add-response-header( "Date", date:now() )
    let $ext           := mvc:extension-for-content-type( $content-type )
    let $template      := if($template) 
                          then fn:lower-case( $template )
                          else 'default'
    let $view-path     := mvc:view-path( $resource, $view, $ext )
    let $template-path := mvc:template-path( $template, $ext )
    let $sections      := mvc:view-map( $view-path, $args )
    return xdmp:invoke( $template-path, (xs:QName("sections"), $sections ) ) 
} catch ( $e ) { mvc:best-available-view() } };

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ errors ~~ :)
declare function mvc:raise-error-from-exception( $e ) {
  mvc:raise-error-from-exception( $e, $default-error-id ) } ;

declare function mvc:raise-error-from-exception( $e, $error-id ) {
  mvc:raise-error-from-exception( $e, $e//error:message/fn:string(), $error-id ) } ;

declare function mvc:raise-error-from-exception( $e, $message, $error-id ) {
  mvc:log( xdmp:quote( $e ) ),
  if ( $e//error:code = 'XDMP-UNDFUN' )
  then mvc:raise-error( $message, 404, 'Not Found' )
  else mvc:raise-error( $message, 500, 'Internal Server Error' ) } ;

declare function mvc:raise-error( $message, $http-code, $http-msg ) {
  mvc:raise-error( $message, $http-code, $http-msg, $default-error-id ) };

declare function mvc:raise-error( $message, $http-code, $http-msg, $error-id ) {
  let $content-type    := mvc:negotiate-content-type()
    let $_ := xdmp:set-response-content-type( $content-type )
    let $_ := xdmp:set-response-code( $http-code, $http-msg )
    let $_ := xdmp:add-response-header( "Date", date:now() )
    return 
      if ( $content-type = "application/xml" )
      then <error id="{$error-id}">{$message}</error>
      else fn:concat('{"error":"',$error-id,'","reason":"',$message,'"}') } ;
