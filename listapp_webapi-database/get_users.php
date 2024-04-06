<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the userId is provided in the POST request
if (isset($_POST['userId']) && isset($_POST['listId'])) {
    // Retrieve userId from POST request
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];

    try {
        // Check if the provided userId exists in the database
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            // Valid userId, proceed to fetch all users excluding the user with the provided userId
            $query = "SELECT * FROM users 
                WHERE userid != ? 
                AND userid NOT IN (
                    SELECT DISTINCT owner 
                    FROM listgrouplink 
                    WHERE listid = ?
                ) 
                AND userid NOT IN (
                    SELECT DISTINCT userid 
                    FROM listgroup 
                    WHERE listgrouplinkid IN (
                        SELECT id 
                        FROM listgrouplink 
                        WHERE listid = ?
                    )
                )
                AND archive = 0";
            $statement = $conn->prepare($query);
            $statement->execute([$userId, $listId, $listId]);
            $users = $statement->fetchAll(PDO::FETCH_ASSOC);

            header('Content-Type: application/json');
            echo json_encode($users);
        } else {
            // Invalid userId
            echo json_encode(['error' => 'Invalid userId']);
        }
    } catch (PDOException $e) {
        // Error handling if the query fails
        echo json_encode(['error' => 'Failed to fetch users: ' . $e->getMessage()]);
    }
} else {
    // Error handling if userId is not provided
    echo json_encode(['error' => 'userId is not provided']);
}
?>
