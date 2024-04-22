<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (isset($_POST['hashedDeviceId'])) {
    $hashedDeviceId = $_POST['hashedDeviceId'];

    try {
        $checkQuery = "SELECT COUNT(*) AS count FROM devices WHERE hashed_device_id = ?";
        $statement = $conn->prepare($checkQuery);
        $statement->execute([$hashedDeviceId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            $updateQuery = "UPDATE devices SET used = used + 1 WHERE hashed_device_id = ?";
            $statement = $conn->prepare($updateQuery);
            $statement->execute([$hashedDeviceId]);
        } else {
            $insertQuery = "INSERT INTO devices (hashed_device_id, used) VALUES (?, 1)";
            $statement = $conn->prepare($insertQuery);
            $statement->execute([$hashedDeviceId]);

            exit();
        }
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Error processing device ID: ' . $e->getMessage()]);
        exit();
    }
} else {
    exit();
}
?>
