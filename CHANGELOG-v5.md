# Changelog V5

## Lyon

* Proposer un template d'une image "native"
  * Peut-être juste proposer un extract des Dockerfiles qui vont bien en plus des images pré-buildées 
* Déploie des images incluant toutes les sources
* Nginx, Fpm : des images séparées
* Déploiement sans coupure : la coupure c'est surement qu'il manque une sonde readyness
* Avoir deux systems différents pour env local et env live 
* Processus zombies sur des crons laravel en mode background (fork du processus)

## Non modifié / todo / non réussi

### Variante rootless 

Une image rootless est une image qui est exécutée au nom de l'utilisateur défini (ici www-data), à la place de root. Exécuter le container sans les droits root est une sécurité supplémentaire vivement recommandée par toutes les bonnes pratiques de sécurité sur la containérisation et imposé dans certains cas (typiquement AWS le bloque par défaut).

Notre image V4 n'est pas rootless car elle disposait de fonctionnalités clés qui en ont fait son succès :
* Le replacement à chaud du UID/GID de l'utilisateur ayant monté un volume dans `/var/www/html` : ceci permet d'éviter des conflits sur les droits de l'utilisateur en développement
* La possibilité l'installer des extensions php diverses directement depuis une variable d'environnement au startup (pratique en développement) 
* La possibilité d'utiliser le `sudo`, ce qui facilite les opérations pour les développeurs moins à l'aise avec les usages sysops => cette justification semble un mauvais prétexte, il suffit de lancer l'image avec un `docker run/exec` sur `--user root` (pas besoin d'un diplôme de sorcellerie avancé).

Pour l'image v5, cela pourrait être le cas mais il y a des choses à adapter : 
* L'image slim serait rootless mais l'image fat ne le serait pas : l'image fat serait ainsi la seule à pouvoir faire le replacement à chaud du UID/GID et installer des extensions php à chaud => cela semble assez cohérent d'autant que l'image fat ne devrait en aucun cas être utilisé en prod (trop long à booter, pas d'intérêt en prod de gérer les UID, entraine une faille dans la sécurité qui posera problèmes à certains clients, etc)
* Il faudrait rendre les fichiers de conf apache, php, etc éditable par l'utilisateur non root (`docker`) : cependant ca serait introduire plus de faille de sécurité encore car du coup il serait éditable par le même user que celui qui execute php.
* Le sudo serait supprimé ou éventuellement ajouté uniquement au `ONBLUID` de l'image slim (et éventuellement disponible pour la fat)
* `s6-overlay` le supporte mais avec [de grosses limitations](https://github.com/just-containers/s6-overlay#user-directive) (et en plus de ce qui est noté, on y voit entre les lignes du ticket original que ce n'est clairement pas [l'approche privilégiée](https://github.com/just-containers/s6-overlay/issues/19) par les mainteneurs)

Autre approche : 
* Nous optons officiellement pour une image non rootless => nous en justifions la sécurité sur une page dédiée de la documentation
* `s6-overlay` permets de choisir très proprement (quand l'image est lancée en root) comment on veut instancier les différentes commandes ou services. On peut donc très bien lancer apache et supercronic en user `daemon` tout en ayant notre script d'initialisation chargée d'installer les extensions php et modifier les configs
* Nous pourrions prévoir deux types d'utilisateurs : un en charge d'initier les services (apache, cron) et un autre en charge d'initier uniquement php. De cette manière : 
  * En dev, nous utiliserions le même utilisateur pour les deux car le code sources et les data utilisateurs doivent appartenir au même utilisateur pour ne pas casser les droits. 
  * En prod, nous séparerions pour que le code source ne puisse pas être édité par les scripts php (meilleur cloisonnement : à l'instar de ce qu'à fait benoit sur le boilerplate v2)
* Nous retirerions la possibilité de changer les UID/GID de manière automatique via la détection de l'appartenance de `/var/www/html` (trop imprecise, facteur d'erreur) et à la place, nous demanderions de spécifier un env UID et un env GID comme beaucoup d'images le font déjà qui deviendra l'UID/GID de l'utilisateur maitre des data en prod et maitre des data et des services en dev. 
* Dans les cas où l'image rootless serait exigée par le client, faudrait prévoir un supplément au forfait de développement pour ajouter un dockerfile adapté à partir de zéro (c'est l'histoire de quelques heures d'autant que les bout de codes de la v5 seront beaucoup plus simple à reprendre pour customiser une image)

Dans tous les cas, c'est un breaking change en terme d'impact sur les déploiements existants : 
* Dans certain cas on utilise la directive `USER` dans les dockerfile ou l'option `user:` dans le docker-compose : ce ne sera plus possible à moins d'installer sudo (ce qui semble une mauvaise idée)
* la séparation en user `daemon` et en user `data` imposera des ajustements sur les images. Pour limiter l'impact il faudrait que l'user `data` soit UID 1000 (et que cet UID puisse être forcé). 

TODO: Définir les users à mettre par défaut


### Alpine version (et ubuntu pour la rétro compatiblité ?)

Désormais :
* La version alpine sera la version par défaut (même tag ?)
* Une version ubuntu continuera d'exister mais uniquement pour la V5 (en V6, elle devrait être supprimé : un message dépracated sera généré), elle facilitera la montée de version
* La version ubuntu ne sera autobuild qu'une fois par mois (sur les versions supportée node/php/apache)
* La version alpine buildera toutes les semaines (sur les versions supportée node/php/apache)

### Versions php et node : toutes

* Toutes les versions php depuis la 5.6 seront build mais seules les versions maintenues les 2 dernières non maintenues seront auto rebuild
* Toutes les versions node depuis la 12 seront build mais seules les versions maintenues les 2 dernières non maintenues seront auto rebuild
* apache ne sera build que sur la dernière version active

Permettre le support plus large des versions php/node sur l'image V5 autorisera plus facilement la montée de version progressive d'application ancienne. C'est un changement de stratégie par rapport à celle initiale qui était de porter moins de versions mais elle représente ainsi un faible coût maintenance donc reste acceptable.

TODO : 
* Faut-il continuer à prebuild les extensions php dans l'image fat ? 
  * Je propose de restreindre cela au minimum : gd, imagick, opcache, redis, apcu, pcov, xdebug, mysqli, pdo_mysql, pdo_pgsql, soap, xmlrpc, xlswriter, yaml, intl, ev, blackfire, calendar, csv, exif, mcrypt
    Cela allongerait les temps de chargement sur les images qui ont besoin de plus... On peut etre plus souple en élargissant cette liste et/ou en autorisant l'image alpine à les avoir toutes.  
  * Je suis d'avis chez TCM de passer par une image slim build spécifiquement même en dev local. Il arrive trop souvent que la facilité d'utiliser l'image fat réduise l'efficacité de nos CI/CD et de nos deployments prod. En mode alpine, cette image serait très rapide à build (1 à 2 minutes). 
* Nous garderons ce que nous avons pour générer la conf php
* Quid de xdebug et blackfire qui ont une install un peu spécifique
* Idem pour imagick et memcache ?

### Génération des confs en shell

En V4 la génération des shell se faisait via un script php. Pratique pour des devs php mais totalement absurde de configurer php avec php. 
Je propose de migrer vers un script bash... par contre ça suppose d'éventuelles régressions et bugs => peut-être différer la chose. 

### Apache mod et apache fpm (php-fpm upgraded)

Je propose de continuer à supporter apache-php, php-cli et php-fpm mais : 
* Prévoir une option pour démarrer apache en side de php-fpm (une option permets de ne pas lancer apache si on veut juste un fpm classique)
* Déprécier apache-mod : en V6 éventuellement supprimer au profit de fpm-apache
  * Plutôt apache ou nginx ? Je trouve apache plus judicieux en mode 'simple' car il supporte les htaccess (importante pour l'autonomie des devs + en prod nous devrions avoir deux images séparées pour http et php-fpm afin d'être conforme au model ideal)
  * Nginx plus facile à étendre 

### Apache modules et conf

Ne pas modifier grand-chose ici. Eventuellement après publication de la V5, initier une évol pour supporter le module [remoteip](https://httpd.apache.org/docs/current/fr/mod/mod_remoteip.html) en autorisant une config simplifiée pour fonctionner derrière un reverse proxy (traefik, nginx ou haproxy).  

## Done / quasiment bon

### Extensions php

Nous utiliserons désormais uniquement https://github.com/mlocati/docker-php-extension-installer, il supporte tout version php depuis php 5.6 (et même 5.5 avec certaines limitations). Il prend en charge plus d'extensions que notre image V4 et garde un support actif. Les extensions disponibles ne seront donc plus listées sur l'images TCM mais un lien pointera vers l'outil tiers.

### Remplacement de tini par https://github.com/just-containers/s6-overlay/

S6-overlay permet un contrôle très soigneux des containers exécutants plusieurs processus. Il est relativement léger (moins de 6Mb en amd64) et permets l'exécutions de tâche en parallel pour les phases d'initialisations, de run et d'arrêt. Il présente aussi de nombreuses fonctionnalités et sécurités qui peuvent être consultée dans la documentation officielle (typiquement : compatibilité avec systemd, contrôle des durées d'instanciations, etc)
Sur des builds de production, nous recommandons d'utiliser la syntaxe officielle de s6-overlay plutôt que les "startups commands" : cela vous permettrait notamment d'exécuter proprement des scripts de type consumer (même si nous recommanderions plutôt d'utiliser des containers distincts pour cela) ou d'adapter la phase d'initialisation du container (tel que l'écriture de fichier de configuration, typiquement dans un wordpress ne supportant pas la récupération des variables d'environnements ou autres vieux frameworks php du même type).

À noter que nativement et si vous choisissez d'en faire usage `supercronic` sera instancié en `longrun` en parallel d'apache et php. En cas de crash de `supercronic`, l'instance crachera du même temps. Ceci permet de nous rapprocher le plus possible d'une bonne pratique docker consistant à ce qu'un container n'ait que deux états (fonctionnel ou arrêté) et donc de profiter des fonctionnalités évoluées des superviseurs (tel kubernetes) pour relancer les containers dysfonctionnels.

Notez cependant que seuls les services cœurs du systems sont monitorés ainsi : si un script php lancé via `apache`, `php-fpm` ou `supercronic` retourne une erreur, le comportement du container restera en état fonctionnel, car cela sort du champ d'application de la partie infra du système (pour évaluer un défaut tel qu'une perte de connexion à une base de données ou une fuite mémoire, nous recommandons l'usage de la commande docker [`HEALTHCHECK`](https://docs.docker.com/engine/reference/builder/#healthcheck) ou celles spécifiques à votre superviseur comme dans [kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)). Si vous souhaitez en bénéficier sur vos commandes spécifiques ou au contraire retirer ce comportement, vous pouvez le configurer [en superposant des règles dans `s6-overlay`](https://github.com/just-containers/s6-overlay/blob/master/README.md#writing-an-optional-finish-script).

TODO : 
* Utiliser le HEALTHCHECK pour gérer si le service qui tombe doit crash le container ou pas ?

#### Breaking changes

* Si le `ENTRYPOINT` a été surchargé, il ne doit plus l'être. En v5, nous vous recommandons vivement de ne plus surcharger l'entrypoint. A la place, ajouter vos instructions sans les services de démarrages de `s6-overlay` ou modifiez directement la `CMD` (celle-ci ne dépend désormais de plus aucun prérequis de fonctionnement).
* Tout appel à `tini` se soldera par un échec : il n'est plus présent dans l'image et NE DOIT PAS / NE PEUT PAS être correctement installé en plus de `s6-overlay`. 
* `STARTUP_COMMAND_*` continue et continuera à être pris en charge comme avant. Les fonctionnalités avancées demanderont néanmoins pour le moment d'utiliser la syntaxe de `s6-overlay` (nous pourrions la prendre en charge par la suite en variable d'environnement). 
* L'arrêt forcé de `supercronic` occasionnera un crash de le container (sic : ce n'est pas supposé survenir...)

A noter que du coté des bonnes nouvelles, le fait de passer par un gestionnaire de processus aussi évolué que `s6-overlay` vous offre :
* une meilleure prise en charge des processus zombies
* une meilleure prise en charge des codes d'erreurs sur l'échec des services imbriqués dans l'image (le container transférera le bon code d'erreur au superviseur docker)
* le loisir d'ajouter sur nos images d'autres services (smtp, mysql, redis...). Nous ne le ferons pas sur l'image principale car cela s'écarte trop des bonnes pratiques que nous voulons recommander mais il devrait être assez facile de surcharger notre image si c'est votre besoin. 


## Modifications mineurs et autres breaking changes

Les comportements réguliers de l'image php officielle :
* Le path de la config php est désormais dans `/usr/local/etc/php/conf.d` au lieu de `/etc/php/${PHP_VERSION}/mods-available/generated_conf.ini`
* La variable `PHP_VERSION` correspond désormais à la version patch de php (ie `8.2.3`), une variable `PHP_VERSION_MINOR` a été ajoutée, elle correspond à l'ancienne valeur soit (ie `8.2`)
* Le binaire de php n'est plus dans `/usr/bin/php` mais dans `/usr/local/bin/php`
  * TODO : prévoir un wrapper deprecated

    Autres : 
* La config php n'est plus régénérée à la volée à chaque execution de php mais uniquement au premier lancement de l'image
  * TODO : Vérifier avec DAN
  * TODO : Vérifier le comportement du container sur des reboot multiples
* `/usr/bin/real_php` n'existe plus, il faut directement utiliser `/usr/local/bin/php`  
  * TODO : prévoir un wrapper deprecated

