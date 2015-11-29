{% from "docker/map.jinja" import docker with context %}

remove-old-versions:
  pkgrepo.absent:
    - name: deb https://get.docker.com/{{ grains.os.lower() }} docker main
  pkg.purged:
    - name: "lxc-docker*"

docker-repo-prereqs:
  pkg.installed:
    - name: apt-transport-https

docker-repo:
  pkgrepo.managed:
    - name: {{ docker.pkgrepo.name }}
    - humanname: Docker Official {{ grains.os }} Repo
    - keyid: {{ docker.pkgrepo.keyid }}
    - keyserver: {{ docker.pkgrepo.keyserver }}
    - file: /etc/apt/sources.list.d/docker.list
    - clean_file: true
    - refresh_db: true
    - require:
      - pkg: apt-transport-https

docker-engine:
  pkg.installed:
    - name: docker-engine
    {% if 'version' in docker %}
    - version: "{{ docker.version }}*"
    {% endif %}
    - require:
      - pkgrepo: docker-repo

{% if docker.opts_type == 'systemd' %}
include: 
  - docker.systemd
{% elif docker.opts_type == 'default' %}

docker-config:
  file.managed:
    - name: /etc/default/docker
    - source: salt://docker/templates/{{ docker.opts_type }}-opts.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true

docker-service:
  service.running:
    - name: docker
    - enable: true
    - restart: true
    - require:
      - pkg: docker-engine
    - watch:
      - file: /etc/default/docker
{% endif %}