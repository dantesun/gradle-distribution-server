# gradle-distribution-server

Provides a set of tools for setting up my own Gradle distribution
server.

1. build.sh: Downloading all required Gradle distributions. Executing
   `./build.sh -h` for details.
2. upload-to-nexus.sh: Uploading all Gradle distributions to a Nexus Raw
   Repository
3. docker-compose.yml: A Nexus 3 server runs locally using Docker.
4. https://github.com/ddimtirov/gwo-agent: Hacks gradle wrapper. Allows
   you replace distribution_url in wrapper.properties

## Why

1. Working with a lot of Gradle projects with different Gradle wrapper
   versions is painful.
2. Writing a Gradle script and test it with different versions of Gradle
   is painful.
3. http://services.gradle.org is unstable and slow in my country.

```
Usage:
${BASH_SOURCE[0]} [-d DIRECTORY] -v PATTERN [-f] [-t bin|all]

          -f: Always fetch versions from Gradle website. Without '-f', it will only fetch the versions into
              ./build/versions.txt once unless you manually delete it.

-d DIRECTORY: The directory where Gradle distributions are stored.

  -v PATTERN: An Awk Regular Expression matches the Gradle version, it will be wrapped in '^PATTERN$'.
              NOTE:
              1. ALWAYS use single quotes around your pattern, ex: '(6.7|6.7.1)', '(6.*)'
                  '6.*' matches all 6.x.x versions.
              2. To match multiple versions, use '(version1|version2)'. For example, '(6.7|6.7.1)' matches two versions,
              3. To match a version range, use patterns like the following.
                 a. '[456].*' will match 4.x.x, 5.x.x and 6.xx.
                 b. '6.1.*' will match 6.1.x and '6.*' will match 6.x and 6.x.x
              4. Please see https://www.gnu.org/software/gawk/manual/html_node/Regexp-Usage.html for details.

  -t bin|all: The Archive type.
              'bin' means gradle-x.x.x-bin.zip which contains no source code.
              'all' means gradle-x.x.x-all.zip with source code.
Example:
  ${BASH_SOURCE[0]} -d ./build/distributions # download all distributions to directory
  ${BASH_SOURCE[0]} -d ./build/distributions -v 4.0.1 # download gradle-4.0.1-all.zip and gradle-4.0.1-bin.zip
  ${BASH_SOURCE[0]} -d ./build/distributions -v 4.0.1 -t all # download gradle-4.0.1-all.zip
  ${BASH_SOURCE[0]} -d ./build/distributions -v '(4.2.1|6.7)' -t all # download gradle-4.0.1-all.zip and gradle-6.7-all.zip
  ${BASH_SOURCE[0]} -d ./build/distributions -v '6.*' -t all # download gradle-6.x.x-all.zip
```
