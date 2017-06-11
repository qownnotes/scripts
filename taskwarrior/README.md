QOwnNotes Taskwarrior
========================

**QOwnNotes Taskwarrior** utility script is a tool, that tries to simplify moving  tasks between your notes and task entries in [Taskwarrior](http://taskwarrior.org). 

# Installation

The recommended way of installing the script is using [QOwnNotes](http://qownnotes.org) script repository (available from `Script settings` under `Scripts` menu). The script is called *Taskwarrior*.

In case you want to modify the script, you may clone `qownnotes/scripts` repository and use `taskwarrior.qml` file directly, loading it as a local script in `Script settings`.

# Usage

## Export (note -> TW)

To export a set of tasks, you need to select text, and then click `Export to Taskwarrior` button (or go to `Scripts` menu for the menu entry). The following rules apply to selected text:

* project names should be formatted as headers, and may be nested
* the tasks are taken only from the unordered list items - lines that are starting with asterisk (*) or minus sign (-)
* any other content will be skipped - any additional comments or empty lines do not matter during the parsing process.

### Example

The following Markdown text:

        ## Project1
        * task one
        ### Subproject1
        * task two
        Some additional portion of text, describing how awesome project 1 is
        * task three
        ### Subproject2
        * task four
        # Project2
        * task five

should generate following calls to Taskwarrior:

        task add pro:Project1 task one
        task add pro:Project1.Subproject1 task two
        task add pro:Project1.Subroject1 task three
        task add pro:Project1.Subproject2 task four
        task add pro:Project2 task five

## Import (TW -> note)

Importing tasks requires listing of projects that tasks will be imported from. When writing a list of projects, please remember about the following rules:

* project names should be formatted as headers, and may be nested
* any other content will be skipped - any additional comments, tasks already written or empty lines do not matter during the parsing process.
* only the tasks from default report will be fetched - usually it means, that only pending tasks are imported
* any metadata of the task are not imported - project name and description are the only thing that are kept.

### Example

Following the example from `Export` section, we want to fetch tasks and import them. 

Selected Markdown text:

        # Project1
        ## Subproject2
        * task four
        ## Subproject1
        Something written here.
        # Project3
        # Project2
        * older task not in Taskwarrior

will be replaced by:

        # Project1
        * task one
        ## Subproject2
        * task four
        * task four
        ## Subproject1
        * task two
        Something written here.
        # Project3
        # Project2
        * task five
        * older task not in Taskwarrior

As you can see, tasks are inserted just after the corresponding header. Other lines are not changed, which may result in duplicates (in case the task was already imported some other time, like in `Subproject2`).

# Settings

Script settings are available in `Script settings` under `Scripts` menu.

## Taskwarrior path

In case your Taskwarrior instance is not in default directory, you may change it to reflect the actual executable path.

## Delete on import

Although not enabled by default, a script may delete task entries from Taskwarrior when they are imported. 

Please, be aware of the risk, that this feature might be bugged in some cases. If you encounter any issues, the recommended way of reverting the changes is using `task undo`. At some point, the Undo feature will be implemented to the script itself as well.

## Verbosity

If you want to monitor logger output in the Event log, it would be advisable to enable this option. Useful for debugging purposes.