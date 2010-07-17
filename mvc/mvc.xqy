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

module  namespace mvc  = "http://ns.dscape.org/2010/dxc/mvc" ;

import module
  namespace gen = "http://ns.dscape.org/2010/dxc/func/gen-tree"
  at "../func/gen-tree.xqy";

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ vars ~~ :)
declare variable $controller-directory := "/ctr/" ;
declare variable $dxc-directory        := "/lib/dxc/" ;
declare variable $pub-directory        := "/pub/" ;
declare variable $invoke-path          := 
  fn:concat( $dxc-directory, "invoke/invoke.xqy" ) ;
declare variable $path-404             := 
  fn:concat( $pub-directory, "404.xqy" ) ;
declare variable $supported-verbs      :=
  ( "GET", "POST", "PUT", "DELETE", "HEAD") ;

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ accessors ~~ :)
declare function mvc:controller-directory() { $controller-directory } ;
declare function mvc:dxc-directory()        { $dxc-directory } ;
declare function mvc:pub-directory()        { $pub-directory } ;
declare function mvc:invoke-path()          { $invoke-path } ;
declare function mvc:path-404()             { $path-404 } ;
declare function mvc:supported-verbs()      { $supported-verbs } ;
declare function mvc:controller-action-path( $controller, $action ) {
  fn:concat( mvc:controller-directory(), 
    $controller, ".xqy?_action=", $action ) };

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ http accessors ~~ :)
declare function mvc:action() { mvc:get-input('action') } ;
declare function mvc:id() { mvc:get-input('id') } ;
declare function mvc:controller() { mvc:get-input('controller') } ;

declare function mvc:get-input( $name ) {
  xdmp:get-request-field( fn:concat('_', $name) ) };

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ redirects ~~ :)
declare function mvc:redirect-to-controller() {
  xdmp:invoke( fn:concat( mvc:controller-directory(), 
    mvc:controller(), ".xqy") ) } ;

declare function mvc:redirect-response() {
  let $url := mvc:get-input( "url" )
  return if ( $url )
         then mvc:redirect-response( xdmp:url-decode( $url ) )
         else mvc:raise-404( () ) } ;

declare function mvc:redirect-response( $url ) {
  xdmp:redirect-response( $ url ) } ;

declare function mvc:function() {
  mvc:function(
    fn:lower-case(
      ( mvc:get-input('action'), xdmp:get-request-method() ) [ . != "" ] [1]))};

declare function mvc:function( $name ) {
  fn:concat( "local:", $name ) } ;

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ forms ~~ :)
declare function mvc:tree-from-request-fields() {
  let $keys   := xdmp:get-request-field-names() [fn:starts-with(., "/")]
  let $values := for $k in $keys return xdmp:get-request-field($k)
  let $_ := xdmp:log(($keys, $values))
  return gen:process-fields( $keys, $values ) } ;

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ errors ~~ :)
declare function mvc:raise-404( $e ) { 
  let $message := fn:string(($e//*:message) [1])
  return (xdmp:set-response-code(404, "Not Found" ), $message) };
