<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (isset($_POST['userId']) && isset($_POST['listId'])) {
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];

    try {
        $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $user = $statement->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            $query = "DELETE FROM listgroup WHERE userid = ? AND listgrouplinkid IN (SELECT id FROM listgrouplink WHERE listid = ?)";
            $statement = $conn->prepare($query);
            $statement->execute([$userId, $listId]);

            if ($statement->rowCount() > 0) {
                echo "success";
            } else {
                echo "ERROR: Failed to leave the group list.";
            }
        } else {
            echo "ERROR: Invalid user.";
        }
    } catch (PDOException $e) {
        echo "ERROR: Failed to execute the query.";
    }
} else {
    echo "ERROR: Required parameters are missing.";
}
?>
