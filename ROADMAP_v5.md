# Roadmap for next major (v5)

## Troubles with v4 

* Too many extensions are build from sources (pickle/pear) so there require long time to build in testing and CI/CD 
* Too many versions/variants (90 version for each platform, so 180 images). It's difficult to ensure a full perimeter for each one (we may have a trouble onto one extension for php 7.2 only on arm64 who block all others)
* Due to that, currently arm version missing 4 php extensions so the same image do not be iso perimeter as the same version for amd. 
* Support of php 4, 5.4 and 5.6 may helpful to allow upgrade old project but currently the solution seem to reduce more the support and remove php <= 7.4. We need to make some choice here (between support and maintainability) 
* It's same for node versions 
* apache variant is most used internally at TCM but 1/ fpm seem to do not work properly 2/ fpm is very more efficient for production server, so we may encourage more this variant. 

## Breaking changes 

* base source : previously base on regular ubuntu image, the v5 will be based by default onto php base image with alpine version. Another version with debian will be supported for retro-compatibility (almost compatible)
* slim/fat version : previously the default image was the fat one, the v5 will recommend by default to use the "regular" one (like the slim old version) and offer a `-dev` tag (like the fat one). It's a change in the name basically but also on the mind : on production you should not use `-dev` one (not optimized for that, even if it's will be still possible and safe). Also, the `-dev` version should be build with a Dockerfile very simple (to help users to understand better how to build their own)
* More regular process : 
  * each tag will have his own Dockerfile on the repository : you can copy past if you have to create your own (security reason, perf, fork, ...) or to make a hotfix
  * no dependencies in Dockerfile (except for `-dev` tag based on regular) : in addition all link should be adjustable (registry base url, tag prefix, etc) to let's anyone to use same file in their own registry as they need (and to have more flexibility about cache management for building)
  * s6-overlay implementation : one starting process = one service (easier to debug, easier to contribute at the project, parallel tasks during starting process, better management of zombie process, ...)
* Lot of attention about the build time : breaking changes are allowed if it's allow to reduce the build time
* Attention to environmental impact : don't rebuild too many variants every week (when php, node or apache is not more supported, it's no more require to rebuild it except for specific execution), pay attention to testing processes... even if it has to slightly reduce the features we would like to offer by default

## Roadmap

- [x] Alpha phase started (RP not expected / reviews asked)
- [ ] Create a draft base branch `v5` where main feature works :
    - [x] Build arm and amd
    - [ ] Only last version of apache, php, node in php alpine base image (to speed up the ci/cd and avoid too much environment impact)
    - [ ] Supercronic 
    - [ ] Impersonate UID/GID for entrypoint
    - [ ] apacheenmod by env var (in entrypoint for -dev or ON BUILD for regular) 
    - [ ] having two testing suites : one for retro-compatibility v4 (who can not work) and another for v5 
    - [ ] Start of documentation for `v5` (breaking changes, mains concepts, migration process) : without too much care about documentation tool and style (juste markdown files / list of mains information)
    - [ ] Linked changed commits (hard reset, rebase, git mv, linear changes commit, ...)... to allow to compare `v4` and `v5` branches  
- [ ] Beta phase started (RP and reviews are welcome, live meeting/coding is possible)
- [ ] Feature to be implemented during the beta phase (non-exhaustive list) : 
  - [ ] Startup commands
  - [ ] PHP.ini and apache.conf customisation with env var (in entrypoint)
  - [ ] phpenmod / installation by env var (in entrypoint for -dev or ON BUILD for regular)
  - [ ] fpm variant implementation (and add a feature to customise the config of fpm server like we have for apache and php)
  - [ ] fpm-apache variant (to have a short path easier than two container : one for http and another for fpm)
  - [ ] Retro-compatibility features (make work the testing suite for retro-compatibility v4 or document the breaking changes)
  - [ ] Complete the regular testing suite
  - [ ] Add debian base image in addition of alpine one (with less variants)
  - [ ] Update the documentation (less information on each page, more pages)
  - [ ] Check feature request and create a roadmap for them (breaking changes can be introduced now but not after the first RC)
- [ ] Release candidate phase (No new features, debug, improve build time, improve security and documentation)
- [ ] Activate the build for v5 and v4 (but only the last version should be actively updated)
- [ ] Deployment as release (announcement, blog article, move onto the regular dockerhub repo, ...)
- [ ] Add a deprecate warning in v4 images, remove of build for v4, and that all (for this part of the story)

### What will happen after the v5 ? 

- Maybe add php 5.6 and some others old version usefull to manage a migration 
- More automations process about security update and new release of node or php
- Starting to deprecate debian version
- Document more to give the right docker path in production (3 containers nginx-phpfpm-node instead of one with all)
- Creation of guides for helmchart, kube kustomiser config, compose, ... (with healcheck, liveness, other good pratices, etc)
- Maybe a option to execute the container without root (too complicated for v5 currently because of UID management and live reconfiguration of php.ini or other feature like that)
- ... then think to the v6

