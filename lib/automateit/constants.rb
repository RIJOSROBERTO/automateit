module AutomateIt # :nodoc:
  # === AutomateIt::Constants
  #
  # Various constants.
  module AutomateIt::Constants
    # AutomateIt version
    VERSION=Gem::Version.new("0.70909")

    # Output prefix for command execution, e.g., "** ls -la"
    PEXEC = "** "

    # Output prefix for notes, e.g., "=> Something happened"
    PNOTE = "=> "

    # Output prefix for errors, e.g., "!! Something bad happened"
    PERROR = "!! "

    # Boilerplate to add to tops of generated files, warning people not to edit
    # them directly.
    WARNING_BOILERPLATE = "# +---------------------------------------------------------------------+
# | WARNING: Do NOT edit this file directly or your changes will be     |
# | lost. If you need to change this file, you must incorporate your    |
# | changes into the AutomateIt project that created it. If you don't   |
# | know what this means, please talk to your system administrator.     |
# +---------------------------------------------------------------------+
#
"
  end

  # Inject constants back into top, providing AutomateIt::VERSION and such.
  module_eval { include Constants }
end
