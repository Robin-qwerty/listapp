<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the required parameters are provided
if (!isset($_POST['userId']) || !isset($_POST['listId'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit();
}

try {
    // Assign parameters to variables
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];

    // Prepare and execute SQL statement to check if user exists
    $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    // Check if user exists
    if ($user) {
        // Update the archive bit of the list to 1
        $updateQuery = "UPDATE lists SET archive = 1 WHERE id = ?";
        $updateStatement = $conn->prepare($updateQuery);
        $updateStatement->execute([$listId]);

        // Return success message
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['error' => 'Invalid userId']);
        exit();
    }
} catch (PDOException $e) {
    // Error handling
    echo json_encode(['error' => 'Failed to delete list: ' . $e->getMessage()]);
}
?>
