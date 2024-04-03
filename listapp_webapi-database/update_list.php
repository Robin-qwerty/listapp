<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the required parameters are provided
if (!isset($_POST['userId']) || !isset($_POST['listId']) || !isset($_POST['listName'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit();
}

try {
    // Assign parameters to variables
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];
    $listName = $_POST['listName'];

    // Prepare and execute SQL statement to check if user exists
    $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    // Check if user exists
    if ($user) {
        // Prepare and execute SQL statement to update list name
        $updateQuery = "UPDATE lists SET name = ? WHERE id = ? AND userid = ? AND archive = 0";
        $updateStatement = $conn->prepare($updateQuery);
        $updateStatement->execute([$listName, $listId, $userId]);

        // Check if any row was affected
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
    // Error handling
    echo json_encode(['error' => 'Failed to update list name: ' . $e->getMessage()]);
}
?>
