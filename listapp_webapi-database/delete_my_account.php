<!DOCTYPE html>
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the request is a POST request
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_GET["deleteuser"])) {
    if (isset($_POST['userId'])) {
        $userId = $_POST['userId'];

        try {
            // Begin transaction
            $conn->beginTransaction();

            // Delete user from 'users' table
            $query = "DELETE FROM users WHERE userid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);

            // Delete lists associated with the user from 'lists' table
            $query = "DELETE FROM lists WHERE userid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);

            // Delete items associated with the user from 'items' table
            $query = "DELETE FROM items WHERE `list-id` IN (SELECT id FROM lists WHERE userid = ?)";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);

            // Delete tasks associated with the user from 'tasks' table
            $query = "DELETE FROM tasks WHERE `list-id` IN (SELECT id FROM lists WHERE userid = ?)";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);

            // Delete list groups associated with the user from 'listgroup' table
            $query = "DELETE FROM listgroup WHERE userid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);

            // Delete list group links associated with the user from 'listgrouplink' table
            $query = "DELETE FROM listgrouplink WHERE owner = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);

            // Commit transaction
            $conn->commit();

            // Respond with success message
            echo "User account and associated data deleted successfully";
        } catch (PDOException $e) {
            // Rollback transaction if any error occurs
            $conn->rollBack();
            echo "Error: " . $e->getMessage();
        }
    } else {
        echo "Error: userId parameter is missing";
    }
} else {
    if ($_SERVER["REQUEST_METHOD"] === "GET" && isset($_GET["login"])) {
        // If it's a GET request and login parameter is set
        echo '
            <form method="post" action="?login">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username"><br>
                <label for="password">Password:</label>
                <input type="password" id="password" name="password"><br>
                <input type="submit" value="Login">
            </form>
        ';
        exit; // Exit to prevent further execution
    } elseif ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["username"]) && isset($_POST["password"])) {
        // If it's a POST request with username and password provided
        $username = $_POST["username"];
        $password = $_POST["password"];
    
        $passwordhashed = hash('sha256', $password, false);

        $sql = "SELECT * FROM users WHERE username = :username AND archive = 0";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(':username', $username);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
        if ($user) {
            if (password_verify($passwordhashed, $user['password'])) {
                // Show confirmation prompt for deleting user account
                echo '
                    <form id="delete-user-form" method="post" action="?deleteuser">
                        <input type="hidden" name="userId" value="' . $user['userid'] . '">
                        <label for="confirm-delete">Are you sure you want to delete your account?</label>
                        <input type="submit" id="confirm-delete" value="Yes, delete my account">
                    </form>
                ';

                // Show confirmation dialog
                echo '
                    <script>
                        document.getElementById("delete-user-form").addEventListener("submit", function(event) {
                            event.preventDefault(); // Prevent form submission
                            
                            // Show confirmation dialog
                            if (confirm("Are you sure you want to delete your account?")) {
                                // If user confirms, submit the form
                                this.submit();
                            } else {
                                // If user cancels, do nothing
                            }
                        });
                    </script>
                ';
            } else {
                echo "Invalid username or password. Please try again.";
            }
        } else {
            echo "Invalid username or password. Please try again.";
        }
    } else {
        // Redirect to login page
        header("Location: ?login");
        exit;
    }
}
?>
