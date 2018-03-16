# Shell Library Component Framework

The Shell Library Component Framework (SLCF) are a set of Bash libraries simplifying scripting and providing a tested environment for rapid development.  Many different library components exist and as such interdependencies are managed across components.  Some libraries are still under development.

## Getting Started

The library functions can be used to simplify the need to write (or in the many cases, rewrite) same or similar snippets of code for purposes of building larger scripts.  The underlying shell libraries have a myriad of unit tests (although not complete) to provide means of testing whether a particular OS can support the current invocation and design.  Getting started using this library generally amounts to the following steps...

* `define SLCF_SHELL_TOP` in your current terminal
* `source ${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh` to get access to some basic core functionality

This will provide the `load_program_library <FULLPATH TO LIBRARY SHELL FILE>` to be used within your scripts to load and utilize that specific Bash library set.

### Prerequisites

Bash 4.x

## Running Tests

The Bash libraries themselves are tested against >2500 tests designed to touch much if not all functionality within each library.  These tests are handled by the RunHarness project.  Furthermore, assertion style functions exist which can be imported into other projects to enhance the develop-test-debug cycle.

The current list of library components are...

* argparsing
* assertions
* base_logging
* base_machinemgt
* base_setup
* cmd_interface
* cmdmgt
* compression
* constants
* debugging
* emailmgt
* execaching
* file_assertions
* filemgt
* hashmaps
* inimgt
* jsonmgt -- [ UNDER CONSTRUCTION -- uses jq or python to accomplish rendering ]
* list
* logging
* machinemgt
* network_assertions
* networkmgt
* newscriptgen
* numerics
* paramfilemgt
* parammgt
* passwordmgt
* pkgmgt
* processmgt
* queue
* rest -- [ UNDER CONSTRUCTION ]
* set_operations
* sshmgt
* stack
* stringmgt
* teamcity
* timemgt
* vmware -- [ UNDER CONSTRUCTION -- uses xmlstarlet or python to accomplish rendering ]
* xmlmgt -- uses xmlstarlet or python to accomplish rendering

### Specialty Libraries for TAP

* tap -- [ UNDER CONSTRUCTION ]

## Contributing

Please read [CONTRIBUTING](CONTRIBUTING.md) for details on code of conduct and the process for submitting pull requests.

## Versioning

Current Version is 1.70

## Authors

* **Michael Klusman**

## License

This project is licensed under MIT License

## Acknowledgments
