(:
 : HTTP Functions
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

module  namespace h  = "http://ns.dscape.org/2010/dxc/http" ;

(: uses a default content type, no 406 errors :)
declare function h:negotiate-content-type( $accept, 
  $supported-content-types, $default-content-type ) {
  let $ordered-accept-types :=
    for $media-range in fn:tokenize($accept, "\s*,\s*")
         let $l := fn:tokenize($media-range, "\s*;\s*")
         let $type   := $l [1]
         let $params := fn:subsequence($l, 2)
         let $quality := (for $p in $params
                         let $q-or-ext := fn:tokenize($p, "\s*=\s*") 
                         where $q-or-ext [1] = "q"
                         return fn:number($q-or-ext[2]), 1.0) [1]
         order by $quality descending
         return $type
  return (for $sat in $ordered-accept-types
           let $match := (for $sct in $supported-content-types
           where fn:matches($sct, fn:replace($sat, "\*", ".*"))
           return $sct) [1]
           return $match, $default-content-type) [1] } ;

declare function h:must-revalidate-cache() {
  xdmp:add-response-header('Cache-Control', 'must-revalidate') } ;

declare function h:no-cache() {
  xdmp:add-response-header('Cache-Control', 'must-revalidate, no-cache'), 
  xdmp:add-response-header('Pragma', 'no-cache'), 
  xdmp:add-response-header('Expires', 'Fri, 01 Jan 1990 00:00:00 GMT'),
  h:etag(xdmp:request()) } ;

declare function h:etag ( $id ) {
  h:etag( $id, fn:true() ) };

declare function h:weak-etag ( $id ) {
  h:etag( $id, fn:false() ) };

declare function h:etag( $id, $strong ) {
  let $str   := fn:concat( '"', xdmp:md5(fn:string($id)), '"' )
  let $etag := if ($strong) then $str else fn:concat("W/", $str)
  return xdmp:add-response-header('ETag', $etag) } ;

