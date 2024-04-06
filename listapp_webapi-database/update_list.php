<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (!isset($_POST['userId']) || !isset($_POST['listId']) || !isset($_POST['listName'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit();
}

try {
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];
    $listName = $_POST['listName'];

    $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $updateQuery = "UPDATE lists SET name = ? WHERE id = ? AND userid = ? AND archive = 0";
        $updateStatement = $conn->prepare($updateQuery);
        $updateStatement->execute([$listName, $listId, $userId]);

        if ($updateStatement->rowCount() > 0) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['error' => 'Failed to update list name']);
        }
    } else {
        echo json_encode(['error' => 'Invalid userId']);
        exit();
    }
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to update list name: ' . $e->getMessage()]);
}
?>
