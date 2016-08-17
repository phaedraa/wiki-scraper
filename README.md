# Rails Interview Project

Mac: (setting up rails)

1. install brew if they don't have it (http://brew.sh/)
2. `brew install rbenv`
3. `rbenv install`
4. `gem install bundler`
5. `git clone git@github.com:clutter/clutter-interview-rails-ng.git`
6. `cd clutter-interview-rails-ng`

That should get you up and running, to run your local server run `rails s` in your terminal, with default settings that will let you access your app at `localhost:3000`

## Objective
Build an application that parses LinkedIn profiles, stores results in a structured manner in a persistent layer and allows to perform search on stored results.

## Tasks
### Backend service
Create a RESTful API containing 3 endpoints:
* Adding a public LinkedIn profile
* Searching for people that were previously added 
* Searching for skills and viewing associated people.
 
The service should parse the following fields from the public profile:
* Name of the person
* Current title
* Current position
* List of skills

### UI
Create a UI that utilizes the above service. The UI should allow users to:
* submit new profiles by passing in a LinkedIn profile URL
* submit searches (utilizing the service searching capabilities described above). Searches should either be by person name or by skill.

## Notes
The application needs to be built with high-volume in mind:
* Assume that a lot of users will be adding profiles for parsing concurrently
* The persistence layer may eventually contain millions of results. Searching through the results still needs to be effective.

## Implementation requirements
* Use Postgres as a database
* Use a Bootstrap based UI
* Use JSON as the data protocol for the API service
* The UI should access the service using AJAX and not using server-side calls.
* Please supply specs for the service
