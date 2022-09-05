{{ $variants := list "apache" "fpm" "cli" }}{{ $versions := list "8.1" "8.0" "7.4" "7.3" "7.2" }}{{ $nodeVersions := list "16" "14" "12" "10" }}
group "default" {
   targets = [
     {{range $phpV := $versions}}
     "php{{ $phpV | replace "." "" }}",{{end}}
   ]
}
{{range $phpV := $versions}}{{range $variant := $variants}}
group "php{{ $phpV | replace "." "" }}-{{ $variant }}-all" {
   targets = [
     "php{{ $phpV | replace "." "" }}-slim-{{ $variant }}",
     "php{{ $phpV | replace "." "" }}-{{ $variant }}",
     {{range $nodeV := $nodeVersions}}"php{{ $phpV | replace "." "" }}-{{ $variant }}-node{{ $nodeV }}",{{end}}
   ]
}{{end}}{{end}}

{{range $phpV := $versions}}
group "php{{ $phpV | replace "." "" }}" {
   targets = [{{range $variant := $variants}}"php{{ $phpV | replace "." "" }}-{{ $variant }}-all",{{end}}]
}{{end}}

variable "REPO" {default = "thecodingmachine/php"}
variable "TAG_PREFIX" {default = ""}
variable "PHP_PATCH_MINOR" {default = ""}
variable "GLOBAL_VERSION" {default = "v4"}

function "tag" {
    params = [PHP_VERSION, VARIANT]
    result = [
        "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${GLOBAL_VERSION}-${VARIANT}",
        notequal("",PHP_PATCH_MINOR) ? "${REPO}:${TAG_PREFIX}${PHP_PATCH_MINOR}-${GLOBAL_VERSION}-${VARIANT}": "",
    ]
}

target "default" {
  context = "."
  args = {
    GLOBAL_VERSION = "${GLOBAL_VERSION}"
  }
  #platforms = ["linux/amd64", "linux/arm64"]
  platforms = [BAKE_LOCAL_PLATFORM]
  pull = true
  output = ["type=docker"] # export in local docker
}

{{range $phpV := $versions}}{{range $variant := $variants}}
###########################
##    PHP {{ $phpV }}
###########################
# thecodingmachine/php:{{ $phpV }}-v4-slim-{{ $variant }}
target "php{{ $phpV | replace "." "" }}-slim-{{ $variant }}" {
  inherits = ["default"]
  tags = tag("{{ $phpV }}", "slim-{{ $variant }}")
  dockerfile = "Dockerfile.slim.{{ $variant }}"
  args = {
    PHP_VERSION = "{{ $phpV }}"
    VARIANT = "{{ $variant }}"
  }
}

# thecodingmachine/php:{{ $phpV }}-v4-{{ $variant }}
target "php{{ $phpV | replace "." "" }}-{{ $variant }}" {
  inherits = ["default"]
  tags = tag("{{ $phpV }}", "{{ $variant }}")
  dockerfile = "Dockerfile.{{ $variant }}"
  args = {
    PHP_VERSION = "{{ $phpV }}"
    VARIANT = "{{ $variant }}"
    FROM_IMAGE = "slim"
  }
  contexts = {
    slim = "target:php{{ $phpV | replace "." "" }}-slim-{{ $variant }}"
  }
}
{{range $nodeV := $nodeVersions}}
# thecodingmachine/php:{{ $phpV }}-v4-{{ $variant }}-node{{ $nodeV }}
target "php{{ $phpV | replace "." "" }}-{{ $variant }}-node{{ $nodeV }}" {
  inherits = ["default"]
  tags = tag("{{ $phpV }}", "{{ $variant }}-node{{ $nodeV }}")
  dockerfile = "Dockerfile.{{ $variant }}.node{{ $nodeV }}"
  args = {
    PHP_VERSION = "{{ $phpV }}"
    VARIANT = "{{ $variant }}-node{{ $nodeV }}"
    FROM_IMAGE = "fat"
  }
  contexts = {
    fat = "target:php{{ $phpV | replace "." "" }}-{{ $variant }}"
  }
}
{{ end }}{{ end }}{{ end }}

