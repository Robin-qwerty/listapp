<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the userId is provided in the GET request
if (isset($_GET['userid'])) {
    // Retrieve userId from GET request
    $userId = $_GET['userid'];

    try {
        // Prepare and execute the query to fetch lists associated with the provided userId
        $query = "SELECT * FROM lists WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $lists = $statement->fetchAll(PDO::FETCH_ASSOC);

        header('Content-Type: application/json');
        echo json_encode($lists);
    } catch (PDOException $e) {
        // Error handling if the query fails
        echo json_encode(['error' => 'Failed to fetch lists: ' . $e->getMessage()]);
    }
} else {
    // Error handling if userId is not provided
    echo json_encode(['error' => 'userid is not provided']);
}
?>
