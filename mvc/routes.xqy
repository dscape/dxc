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
declare namespace c = "http://ns.dscape.org/2010/dxc/cache" ;

declare function r:kvpair( $k, $v ) {
  <c:kvp key="{ $k }" regexp="{r:generate-regular-expression($k)}" value="{ $v }"/> };

declare function r:resource($node) {
  let $r     := $node/@name
  return ( 
    for $include in $node/rc:include
      let $action := fn:data( $include/@action )
      let $verbs  := fn:tokenize($include/@methods, ',')
      for $verb in $verbs
        let $k := fn:concat($verb, " /", $r,"/:id/", $action)
        let $v := mvc:controller-action-path( $r, fn:concat($verb, "-", $action) )
        return r:kvpair( $k, $v ),
    for $verb in mvc:supported-verbs()
      let $k := fn:concat( $verb, " /", $r, "/:id" )
      let $v := mvc:controller-action-path( $r, $verb )
      return r:kvpair( $k, $v ) ) } ;

declare function r:match( $node ) { 
  let $k := fn:concat( "GET ", $node/@path )
    return if ( $node/rc:to )
           then let $to := fn:tokenize( fn:normalize-space( $node/rc:to ), "#" )
                  let $v := mvc:controller-action-path( $to [1], $to [2] )
                  return r:kvpair( $k, $v )
           else if ( $node/rc:redirect-to ) 
                then r:kvpair( $k,
                       fn:concat( mvc:invoke-path(), 
                         "?_action=redirect&amp;_url=",
                       xdmp:url-encode(
                         fn:normalize-space( $node/rc:redirect-to ) ) ) )
                else r:kvpair( $k, fn:concat( mvc:invoke-path(), "?_" ) ) } ;

declare function r:root($node) {
  let $ra   := fn:tokenize ( fn:normalize-space( fn:string($node) ), "#" ) 
    let $file := mvc:controller-action-path( $ra [1], $ra [2] )
    return r:kvpair("GET /", $file) } ;

declare function r:head( $node)   { r:verb( $node, 'HEAD'   ) };
declare function r:put( $node)    { r:verb( $node, 'PUT'    ) };
declare function r:post( $node)   { r:verb( $node, 'POST'   ) };
declare function r:delete( $node) { r:verb( $node, 'DELETE' ) };

declare function r:verb( $node, $verb ) { 
  let $k := fn:concat( $verb, ' ', $node/@path )
    let $to := fn:tokenize( fn:normalize-space( $node ), "#" )
    let $v := mvc:controller-action-path( $to [1], $to [2] )
      return r:kvpair( $k, $v ) } ;

declare function r:transform( $node ) {
  typeswitch ( $node )
    case element( rc:match )    return r:match( $node )
    case element( rc:head )     return r:head( $node )
    case element( rc:delete )   return r:delete( $node )
    case element( rc:post )     return r:post( $node )
    case element( rc:put )      return r:put( $node )
    case element( rc:resource ) return r:resource( $node )
    case element( rc:root )     return r:root( $node )
    default                     return () } ;

declare function r:generate-regular-expression($node) {
  let $t := fn:replace( fn:normalize-space($node), "/:id", "/?([\\w|\\-|_|\\.]+)?" )
  return fn:concat(fn:replace( $t , ":([\w|\-|_]+)", "([\\w|\\-|_|\\.]+)" ), 
    if(fn:tokenize($t, " ")[2]="/") then "" else "(/)?") };

declare function r:extract-labels($node) {
  fn:analyze-string($node, ":([\w|\-|_]+)") //s:match/s:group/fn:string(.) } ;

declare function r:routes( $routes-cfg ) { 
  <c:cache> { let $r := document { $routes-cfg }
      return for $e in $r/rc:routes/* return r:transform($e) }
  </c:cache> } ;

declare function r:selected-route( $routes-cfg ) {
  r:selected-route( $routes-cfg, 
    xdmp:get-request-url(), 
    xdmp:get-request-method() ) };

declare function r:selected-route( $routes-cfg, $url, $verb ) {
  let $tokens := fn:tokenize( $url, '\?' )
  let $route  := $tokens [1]
  let $args   := $tokens [2]
  let $req := fn:string-join( ( $verb, $route), " ")
  return
    let $cache := r:routes( $routes-cfg )
      let $selected := $cache //c:kvp [ fn:matches( $req, @regexp ) ] [1]
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
               return fn:concat($file, $params, 
                 if ($args) then fn:concat("&amp;", $args) else "")
           else let $pub := fn:replace(mvc:pub-directory(), "/$", "")
                  return    fn:concat($pub, $route) } ;
