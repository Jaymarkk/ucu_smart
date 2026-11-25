# Building Location Information

The existing Campus Navigation screen loads active, public buildings through
the current building API and displays database-backed buildings in its
searchable building list. Tap a listed building to open its details.

## Location information

The details view uses the building's existing database fields:

1. `location_details` is shown as the building's campus location when present.
2. Otherwise, `description` is used as the location information.
3. If both fields are missing or blank, the app displays:
   **Location information is not yet available.**

Map-marker availability is shown separately from location text. A location
description does not create or imply map coordinates. Buildings without saved
map coordinates remain available in the list and details view but do not get a
map marker.

## Directions

Location information alone does not enable directions. Directions remain
available only when the building has valid saved map coordinates, an existing
campus graph node, and a verified walkable connection to the campus path
network.
