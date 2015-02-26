<?php
echo "MySQL Test.";
$link = mysql_connect('172.31.5.255', 'apache', 'password');
if (!$link) {
    die('Could not connect: ' . mysql_error());
}
echo 'Connected successfully';
mysql_close($link);
?>
