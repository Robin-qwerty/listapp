<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (isset($_POST['userId']) && isset($_POST['groupCode'])) {
    $userId = $_POST['userId'];
    $groupCode = $_POST['groupCode'];

    // try {
        // Check if the user with the provided userId exists
        $query = "SELECT * FROM users WHERE userid = ?";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $user = $statement->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            echo json_encode(['message' => 'Error: Invalid userId']);
            exit;
        }

        $query = "SELECT groupid FROM invite WHERE code = ?";
        $statement = $conn->prepare($query);
        $statement->execute([$groupCode]);
        $invite = $statement->fetch(PDO::FETCH_ASSOC);

        if ($invite) {
            $groupId = $invite['groupid'];

            $query = "SELECT * FROM listgrouplink WHERE listid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$groupId]);
            $listGroupLink = $statement->fetch(PDO::FETCH_ASSOC);

            if ($listGroupLink) {
                $listGroupLinkId = $listGroupLink['id'];

                $query = "SELECT * FROM listgroup WHERE userid = ? AND listgrouplinkid = ?";
                $statement = $conn->prepare($query);
                $statement->execute([$userId, $listGroupLinkId]);
                $existingMembership = $statement->fetch(PDO::FETCH_ASSOC);

                if (!$existingMembership) {
                    $query = "INSERT INTO listgroup (userid, listgrouplinkid) VALUES (?, ?)";
                    $statement = $conn->prepare($query);
                    $statement->execute([$userId, $listGroupLinkId]);

                    echo json_encode(['message' => 'Joined group successfully']);
                } else {
                    echo json_encode(['message' => 'User is already a member of this group']);
                }
            } else {
                echo json_encode(['message' => 'Error: listgrouplink not found for groupid']);
            }
        } else {
            echo json_encode(['message' => 'Error: Group code not found or expired']);
        }
    // } catch (PDOException $e) {
    //     echo json_encode(['message' => 'Error: ' . $e->getMessage()]);
    // }
} else {
    echo json_encode(['message' => 'Error: Missing parameters']);
}
?>
