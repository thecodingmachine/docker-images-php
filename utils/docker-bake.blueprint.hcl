{{ $variants := list "apache" "fpm" "cli" }}{{ $versions := list "8.5" "8.4" "8.3" "8.2" "8.1" "8.0" "7.4" }}{{ $nodeVersions := list "26" "24" "22" }}{{ $legacyVersions := list "8.1" "8.0" "7.4" }}{{ $legacyNodeVersions := list "26" "24" "22" "20" "18" }}{{ $oldNodeVersions := list "20" "18" }}
group "default" {
   targets = [
     {{range $phpV := $versions}}
     "php{{ $phpV | replace "." "" }}",{{end}}
   ]
}
{{range $phpV := $versions}}{{range $variant := $variants}}{{ $nodes := $nodeVersions }}{{ if has $phpV $legacyVersions }}{{ $nodes = $legacyNodeVersions }}{{ end }}
group "php{{ $phpV | replace "." "" }}-{{ $variant }}-all" {
   targets = [
     "php{{ $phpV | replace "." "" }}-slim-{{ $variant }}",
     "php{{ $phpV | replace "." "" }}-{{ $variant }}",
     {{range $nodeV := $nodes}}"php{{ $phpV | replace "." "" }}-{{ $variant }}-node{{ $nodeV }}",{{end}}
   ]
}{{ if not (has $phpV $legacyVersions) }}
# NodeJS versions no longer maintained, built by the legacy workflow
group "php{{ $phpV | replace "." "" }}-{{ $variant }}-legacy-node" {
   targets = [
     "php{{ $phpV | replace "." "" }}-slim-{{ $variant }}",
     "php{{ $phpV | replace "." "" }}-{{ $variant }}",
     {{range $nodeV := $oldNodeVersions}}"php{{ $phpV | replace "." "" }}-{{ $variant }}-node{{ $nodeV }}",{{end}}
   ]
}{{ end }}{{end}}{{end}}

{{range $phpV := $versions}}
group "php{{ $phpV | replace "." "" }}" {
   targets = [{{range $variant := $variants}}"php{{ $phpV | replace "." "" }}-{{ $variant }}-all",{{end}}]
}{{end}}

variable "REPO" {default = "thecodingmachine/php"}
variable "TAG_PREFIX" {default = ""}
variable "PHP_PATCH_MINOR" {default = ""}
variable "IS_RELEASE" {default = "0"}
variable "GLOBAL_VERSION" {default = "v5"}
variable "ARCH_SUFFIX" {default = ""}

function "tag" {
    params = [PHP_VERSION, VARIANT]
    result = [
      equal("1",IS_RELEASE) ? "${REPO}:${PHP_VERSION}-${GLOBAL_VERSION}-${VARIANT}${ARCH_SUFFIX}" : "",
      equal("1",IS_RELEASE) ? (notequal("",PHP_PATCH_MINOR) ? "${REPO}:${PHP_PATCH_MINOR}-${GLOBAL_VERSION}-${VARIANT}${ARCH_SUFFIX}": "") : "",
      "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${GLOBAL_VERSION}-${VARIANT}${ARCH_SUFFIX}",
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

{{range $phpV := $versions}}
###########################
##    PHP {{ $phpV }}
###########################
# Layers shared by the images of all the variants (not published)
target "php{{ $phpV | replace "." "" }}-base" {
  inherits = ["default"]
  dockerfile = "Dockerfile.base"
  output = ["type=cacheonly"]
  args = {
    PHP_VERSION = "{{ $phpV }}"
  }
}

target "php{{ $phpV | replace "." "" }}-extensions" {
  inherits = ["default"]
  dockerfile = "Dockerfile.extensions"
  output = ["type=cacheonly"]
  contexts = {
    base = "target:php{{ $phpV | replace "." "" }}-base"
  }
}
{{range $variant := $variants}}{{ $nodes := $legacyNodeVersions }}
# thecodingmachine/php:{{ $phpV }}-v5-slim-{{ $variant }}
target "php{{ $phpV | replace "." "" }}-slim-{{ $variant }}" {
  inherits = ["default"]
  tags = tag("{{ $phpV }}", "slim-{{ $variant }}")
  dockerfile = "Dockerfile.slim.{{ $variant }}"
  args = {
    VARIANT = "{{ $variant }}"
  }
  contexts = {
    base = "target:php{{ $phpV | replace "." "" }}-base"
  }
}

# The slim image of the variant with the extensions (not published)
target "php{{ $phpV | replace "." "" }}-slim-{{ $variant }}-with-extensions" {
  inherits = ["default"]
  dockerfile = "Dockerfile.slim.{{ $variant }}"
  args = {
    VARIANT = "{{ $variant }}"
  }
  output = ["type=cacheonly"]
  contexts = {
    base = "target:php{{ $phpV | replace "." "" }}-extensions"
  }
}

# thecodingmachine/php:{{ $phpV }}-v5-{{ $variant }}
target "php{{ $phpV | replace "." "" }}-{{ $variant }}" {
  inherits = ["default"]
  tags = tag("{{ $phpV }}", "{{ $variant }}")
  dockerfile = "Dockerfile.{{ $variant }}"
  args = {
    VARIANT = "{{ $variant }}"
  }
  contexts = {
    slim-with-extensions = "target:php{{ $phpV | replace "." "" }}-slim-{{ $variant }}-with-extensions"
  }
}
{{range $nodeV := $nodes}}
# thecodingmachine/php:{{ $phpV }}-v5-{{ $variant }}-node{{ $nodeV }}
target "php{{ $phpV | replace "." "" }}-{{ $variant }}-node{{ $nodeV }}" {
  inherits = ["default"]
  tags = tag("{{ $phpV }}", "{{ $variant }}-node{{ $nodeV }}")
  dockerfile = "Dockerfile.{{ $variant }}.node"
  args = {
    PHP_VERSION = "{{ $phpV }}"
    VARIANT = "{{ $variant }}-node{{ $nodeV }}"
    FROM_IMAGE = "fat"
    NODE_VERSION = "{{ $nodeV }}"
  }
  contexts = {
    fat = "target:php{{ $phpV | replace "." "" }}-{{ $variant }}"
  }
}
{{ end }}{{ end }}{{ end }}

