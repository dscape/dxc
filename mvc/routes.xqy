(:
 : Routing Functions
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

module  namespace r  = "http://ns.dscape.org/2010/dxc/mvc/routes" ;

declare namespace rc = "http://ns.dscape.org/2010/routes" ;
declare namespace s  = "http://www.w3.org/2009/xpath-functions/analyze-string" ;

import module
  namespace mvc = "http://ns.dscape.org/2010/dxc/mvc"
  at "/lib/dxc/mvc/mvc.xqy";
import module
  namespace c = "http://ns.dscape.org/2010/dxc/cache"
  at "../cache/cache.xqy";

declare function r:match( $node ) { 
  let $k := fn:concat( "GET ", $node/@path )
    return if ( $node/rc:to )
           then let $to := fn:tokenize( fn:normalize-space( $node/rc:to ), "#" )
                  let $file := fn:concat( mvc:controller-directory(), $to[1], 
                                          ".xqy?_action=", $to[2] )
                  return c:kvpair( $k, $file )
           else if ( $node/rc:redirect-to ) 
                then c:kvpair( $k,
                       fn:concat( mvc:invokable-path(), 
                         "?_action=redirect&amp;_url=",
                       xdmp:url-encode(
                         fn:normalize-space( $node/rc:redirect-to ) ) ) )
                else c:kvpair( $k, fn:concat( mvc:invokable-path(), "?_" ) ) } ;

declare function r:resource($node) {
  let $r     := $node/@name
    for $verb in mvc:verbs()
      let $k := fn:concat( $verb, " /", $r, "/:id" )
      let $v := fn:concat( mvc:controller-directory(), $r, ".xqy?_action=", $verb )
    return c:kvpair( $k, $v ),
  let $r         := $node/@name
    let $actions :=  fn:data( $node/r:include/@action )
    for $action in $actions
      let $k := fn:concat("GET /", $r,"/:id/", $action)
      let $v := fn:concat( mvc:controller-directory(), $r, ".xqy?_action=", $action )
    return c:kvpair( $k, $v ) } ;

declare function r:root($node) {
  let $ra   := fn:tokenize ( fn:normalize-space( fn:string($node) ), "#" ) 
    let $file := fn:concat( mvc:controller-directory(), $ra [1],
                            ".xqy?_action=", $ra [2] )
    return c:kvpair("GET /", $file) } ;

declare function r:transform( $node ) {
  typeswitch ( $node ) (: we need an extra match for each verb that isnt get :)
    case element( rc:match )    return r:match( $node )
    case element( rc:resource ) return r:resource( $node )
    case element( rc:root )     return r:root( $node )
    default                     return () } ;

declare function r:generate-regular-expression($node) {
  fn:replace( $node , ":([\w|\-|_]+)", "([\\w|\\-|_]+)" ) } ;

declare function r:extract-labels($node) {
  fn:analyze-string($node, ":([\w|\-|_]+)") //s:match/s:group/fn:string(.) } ;

declare function r:routes( $routes-cfg ) { 
  <c:cache> { let $r := document { $routes-cfg }
      return for $e in $r/rc:routes/* return r:transform($e) }
  </c:cache> } ;

declare function r:selected-route( $routes-cfg ) {
let $route  := xdmp:get-request-path()
  let $verb := xdmp:get-request-method()
  let $req := fn:string-join( ( $verb, $route), " ")
  return 
    if ( fn:matches($req,  "GET /(img|css|js)/.*") )
    then fn:concat("/pub", $route)
    else
      let $cache := r:routes( $routes-cfg )
        let $selected := $cache //c:kvp [ fn:matches( $req, fn:concat( 
          r:generate-regular-expression(@key), "$" ) ) ] [1]
        return 
          if ($selected)
          then let $route     := $selected/@key
                 let $file    := $selected/@value
                 let $regexp  := r:generate-regular-expression( $route )
                 let $labels  := r:extract-labels( $route )
                 let $matches := fn:analyze-string( $req, $regexp ) 
                   //s:match/s:group/fn:string(.)
                 let $params := 
                   if ($matches) 
                   then fn:concat( "&amp;",
                     fn:string-join( for $match at $p in $matches
                       return fn:concat("_", $labels[$p], "=",
                       xdmp:url-encode($match)) , "&amp;") )
                   else ""
                 return fn:concat($file, $params)
             else mvc:redirect-404() } ;
