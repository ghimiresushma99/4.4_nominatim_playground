# Baato Nominatim Playground

This tool allows to play with Nominatim API and tweak the configuration to meet the needs.

# About

This playground uses code snippets from [Nominatim 4.4](https://github.com/mediagis/nominatim-docker/tree/master/4.4). But certain modifications are done to suit our needs as follows:

- Address lookup SQL functions have been overriden (see file `lib/nominatim/lib-sql/functions/address_lookup.sql`)
- Address config has been customized (see file `etc/nominatim/address-levels.json`)

# Installation

- Clone the repository

# Preparation and running

- Make a folder called `data` in the project root
- Add `data.osm.pbf` inside the `data` folder
- ` docker-compose build`
- `docker-compose up`

Now the Nominatim interface should be available at [http://localhost:8090/](http://localhost:8090/).

# Changing address configuration

- Address configuration: To change the address config, edit the file `/address.config-custom.json `
- Again build the app with `docker-compose build`
- Run it with `docker-compose up` to see the changes at [http://localhost:8090/](http://localhost:8090/).

# Useful materials

- Nominatim Manual- https://nominatim.org/release-docs/develop/
- Nominatim Docker releases- https://github.com/mediagis/nominatim-docker
