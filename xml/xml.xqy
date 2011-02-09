(:
 : XML functions
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

module namespace x = "http://ns.dscape.org/2010/dxc/xml" ;

declare function x:change-element-ns( $e, $ns) {
  element { QName( $ns, local-name( $e ) ) }
          { $e/@*, $e/node() } } ;

declare function x:strip-namespaces( $e ) {
  element { QName((), local-name( $e )) } 
    { for $x in $e/( @*,node() )
      return if ($c instance of element()) then x:strip-namespaces($c) else $c } };