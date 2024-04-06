<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the userId is provided in the GET request
if (isset($_GET['userid'])) {
    // Retrieve userId from GET request
    $userId = $_GET['userid'];

    try {
        // Check if the provided userId exists in the database
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            // Valid userId, proceed to fetch lists associated with the userId
            $query = "SELECT * FROM lists WHERE userid = ? AND archive = 0";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);
            $lists = $statement->fetchAll(PDO::FETCH_ASSOC);

            header('Content-Type: application/json');
            echo json_encode($lists);
        } else {
            // Invalid userId
            echo json_encode(['error' => 'Invalid userId']);
        }
    } catch (PDOException $e) {
        // Error handling if the query fails
        echo json_encode(['error' => 'Failed to fetch lists: ' . $e->getMessage()]);
    }
} else {
    // Error handling if userId is not provided
    echo json_encode(['error' => 'userid is not provided']);
}
?>
