(:
 : Sequence functions
 :
 : Copyright (c) 2010 Nuno Job [nunojob.com], Bob Starbird.
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

module namespace seq = "http://ns.dscape.org/2010/dxc/sequence" ;

declare function seq:sequence-to-map( $l ) {
    let $map := map:map()
    let $_ := for $p in ( 1 to fn:count( $l ) ) [ . mod 2 ne 0 ]
                return map:put( $map, $l [ $p ], seq:to-seq( $l[ $p+1 ] ) )
    return $map } ;

declare function seq:from-seq( $seq ) {
 <rowset> { for $e in $seq return <row>{$e}</row> } </rowset> } ;

declare function seq:to-seq( $rowset ) {
  for $node in $rowset//row/(text()|node())
  return typeswitch ( $node )
    case text()     return fn:string( $node )
    default         return $node } ;

