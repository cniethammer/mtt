<?php
#
# Copyright (c) 2005-2006 The Trustees of Indiana University.
#                         All rights reserved.
# $COPYRIGHT$
# 
# Additional copyrights may follow
# 
# $HEADER$
#

$local = "/u/jsquyres/perfbase";

$mtt_pb_config = array
(
  env => array
  (
    PATH => "$local:/opt/python-2.4/bin:" . $_ENV[PATH],
    PYTHONPATH => "$local/lib/python2.4:$local/lib/python2.4/site-packages" . (isset($_ENV[PYTHONPATH]) ? ":$_ENV[PYTHONPATH]" : ""),
    PB_DBUSER => "postgres",
    PB_DBPASSWD => "insert password here",
    ),
  cwd => "/tmp",
  debug => 1,
  );
