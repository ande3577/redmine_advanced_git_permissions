# Advanced Git Permission

## Introduction

Works in concert with a git smart http server and git update hook to limit 
access to a git repository to select users.  It provides the following 
permissions:

* Create branch
* Delete branch
* Update protected branch
* Non ff branch
* Create tag
* Delete tag
* Update tag
* Update protected tag 
* Manage ref rules 

Works on redmine 2.2.x

## Installation

1. Clone the plugin to: plugins/redmine_advanced_git_permissions
1. Migrate the database
> rake redmine:plugins:migrate RAILS_ENV=production
1. Restart the server

## Git Setup

1. Enable WS and generate a secret key
1. Setup a smart http server following the instructions provided on the redmine 
website
1. Copy hooks/update and correct the host address and secret key
1. Include a copy of the update hook in all git repositories (or set it up as a 
template)

## Usage

Set the appropriate permission based on project roles.

In the repository settings, select "Manage Ref Rules" to define rules for 
allowed or protected branches or tags.

Rules obey the following precedence:

1. Illegal refs
2. Protected refs
3. Public refs

A default rule can be used to set the permissions on a ref that does not match 
any rule. Rules can be defined either to be an exact match or a regular 
expression.

An administrator can also declare global rules that can optionally be inherited 
by a repository.

## License

This program is free software: you can redistribute it and/or modify 
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
