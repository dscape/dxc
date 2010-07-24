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
  at "mvc.xqy";
import module
  namespace c = "http://ns.dscape.org/2010/dxc/cache"
  at "../cache/cache.xqy";

declare function r:match( $node, $method ) { 
  let $k := fn:concat( $method, " ", $node/@path )
    return if ( $node/rc:to )
           then let $to := r:tokenize-by-pound( $node/rc:to )
                  let $v := mvc:controller-action-path( $to [1], $to [2] )
                  return c:kvpair( $k, $v )
           else if ( $node/rc:redirect-to ) 
                then c:kvpair( $k,
                       fn:concat( mvc:invoke-path(), 
                         "?_action=redirect&amp;_url=",
                       xdmp:url-encode(
                         fn:normalize-space( $node/rc:redirect-to ) ) ) )
                else c:kvpair( $k, fn:concat( mvc:invoke-path(), "?_" ) ) } ;

declare function r:get( $node )    { r:match($node, "GET") } ;
declare function r:head( $node )   { r:match($node, "HEAD") } ;
declare function r:put( $node )    { r:match($node, "PUT") } ;
declare function r:post( $node )   { r:match($node, "POST") } ;
declare function r:delete( $node ) { r:match($node, "DELETE") } ;

declare function r:root($node) {
  let $ra   := r:tokenize-by-pound( $node ) 
    let $file := mvc:controller-action-path( $ra [1], $ra [2] )
    return c:kvpair("GET /", $file) } ;

declare function r:resource($node) {
  let $r     := $node/@name
    for $verb in mvc:supported-verbs()
      let $k := fn:concat( $verb, " /", $r, "/:id" )
      let $v := mvc:controller-action-path( $r, $verb )
    return c:kvpair( $k, $v ),
  let $r         := $node/@name
    for $action in fn:data( $node/r:include/@action )
      let $k := fn:concat("GET /", $r,"/:id/", $action)
      let $v := mvc:controller-action-path( $r, $action )
    return c:kvpair( $k, $v ) } ;

declare function r:tokenize-by-pound( $node ) {
  fn:tokenize ( fn:normalize-space( fn:string( $node ) ), "#" ) } ;

declare function r:transform( $node ) {
  typeswitch ( $node )
    case element( rc:match )    return r:get( $node )
    case element( rc:head )     return r:head( $node )
    case element( rc:delete )   return r:delete( $node )
    case element( rc:post )     return r:post( $node )
    case element( rc:put )      return r:put( $node )
    case element( rc:resource ) return r:resource( $node )
    case element( rc:root )     return r:root( $node )
    default                     return () } ;

declare function r:generate-regular-expression($node) {
  fn:concat(fn:replace( $node , ":([\w|\-|_]+)", "([\\w|\\-|_]+)" ), "(/)?") };

declare function r:extract-labels($node) {
  fn:analyze-string($node, ":([\w|\-|_]+)") //s:match/s:group/fn:string(.) } ;

declare function r:extract-values($req, $regexp){
  fn:analyze-string( $req, $regexp ) //s:match/s:group/fn:string(.) } ;

declare function r:routes( $cfg ) { 
  <c:cache> { let $r := document { $cfg }
      return for $e in $r/rc:routes/* return r:transform($e) }
  </c:cache> } ;

declare function r:selected-route( $routes ) {
let $route  := xdmp:get-request-path()
  let $verb := xdmp:get-request-method()
  let $req := fn:string-join( ( $verb, $route), " ")
  return
    let $cache := $routes
      let $selected := $cache //c:kvp [ fn:matches( $req, fn:concat( 
        r:generate-regular-expression(@key), "$" ) ) ] [1]
      return 
        if ($selected)
        then let $route     := $selected/@key
               let $file    := $selected/@value
               let $args    := fn:tokenize(xdmp:get-request-url(), "\?")[2]
               let $regexp  := r:generate-regular-expression( $route )
               let $labels  := r:extract-labels( $route )
               let $matches := r:extract-values( $req, $regexp )
               let $params := 
                 if ($matches) 
                 then fn:concat( "&amp;",
                   fn:string-join( for $match at $p in $matches
                     return fn:concat("_", $labels[$p], "=",
                     xdmp:url-encode($match)) , "&amp;") )
                 else ""
               return fn:concat($file, $params, 
                 if ($args) then fn:concat("&amp;", $args) else "")
           else let $pub := fn:replace(mvc:pub-directory(), "/$", "")
                  return    fn:concat($pub, $route) } ;
