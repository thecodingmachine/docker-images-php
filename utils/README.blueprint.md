Base Docker PHP images.

## Apache
{{ $image := .Values.Images.apache }}
### php:{{ $image.php_version }}-apache

| Name                       | Version                                         |
|----------------------------|-------------------------------------------------|
| APCu                       | `{{ $image.apcu_version }}`               |
| PHP extension for Redis    | `{{ $image.phpredis_version }}`           |
| YAML                       | `{{ $image.yaml_version }}`               |
| Xdebug                     | `{{ $image.xdebug_version }}`             |
| Composer                   | `{{ $image.composer_version }}`           |
| prestissimo                | `{{ $image.prestissimo_version }}`        |
| PHP Coding Standards Fixer | `{{ $image.php_cs_fixer_version }}`       |
| NodeJS                     | `{{ $image.node_version }}`               |
| yarn                       | `{{ $image.yarn_version }}`               |