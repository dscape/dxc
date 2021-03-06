(:
 : Invoking Script
 :
 : Three ways to operate:
 :  - redirect-to sends you to a new page
 :  - if the function doesn't exist than we want to call that function
 :    in a /:resource/:action/:id fashion
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
xquery version "1.0-ml";

import module
  namespace mvc = "http://ns.dscape.org/2010/dxc/mvc"
  at "../mvc/mvc.xqy";

declare function local:redirect() { mvc:redirect-response() } ;

declare function local:default() { mvc:redirect-to-controller() } ;

declare function local:file-from-db(){
  let $uri := xdmp:get-request-field( "_uri" )
    let $format := xdmp:uri-format( $uri )
    let $mimetype := xdmp:uri-content-type( $uri )
    let $doc := fn:doc($uri) (: improve for multiple dbs will be needed :)
    return if ( $doc )
           then ( xdmp:set-response-content-type( $mimetype ), $doc )
           else () };

try          { 
  let $action := mvc:action()
  let $f      := if ($action = "redirect" )
                 then mvc:function( "redirect" )
                 else if( $action = "file-from-db" )
                      then mvc:function( "database" )
                      else mvc:function( "default" )
    return xdmp:apply( $f ) }
catch ( $e ) {  mvc:raise-error-from-exception( $e ) }
