# Roadmap for next major (v5)

## Troubles with v4 

* Too many extensions are build from sources (pickle/pear) so there require long time to build in testing and CI/CD 
* Too many versions/variants (90 version for each platform, so 180 images). It's difficult to ensure a full perimeter for each one (we may have a trouble onto one extension for php 7.2 only on arm64 who block all others)
* Due to that, currently arm version missing 4 php extensions so the same image do not be iso perimeter as the same version for amd. 
* Support of php 4, 5.4 and 5.6 may helpful to allow upgrade old project but currently the solution seem to reduce more the support and remove php <= 7.4. We need to make some choice here (between support and maintainability) 
* It's same for node versions 
* apache variant is most used internally at TCM but 1/ fpm seem to do not work properly 2/ fpm is very more efficient for production server so we may encourage more this variant. 

