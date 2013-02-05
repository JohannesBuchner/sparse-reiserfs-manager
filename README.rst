Manager to create and resize reiserfs sub-filesystems, which are stored in sparse files.
=============================

What is this about?
--------------------

You can create files which contain reiserfs filesystems.
This is useful for trees having many small files: reiserfs is very fast in that, and packs them well.
These files can than be be loop-mounted onto another directory so you can access them.

For saving space, you can create sparse files, which grow as empty space is written to.

Finally, you can resize the partition using resize_reiserfs and truncate (in the right order, depending on whether you want to shrink or grow your file system). The filesystem has to be unmounted for that.

This script automates all of this: creation, expanding, shrinking, removal.




