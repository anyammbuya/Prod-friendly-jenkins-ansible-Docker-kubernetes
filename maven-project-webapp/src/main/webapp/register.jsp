<!DOCTYPE html>
<html>
<head>
    <title>Create Account</title>
</head>
<body>

<h2>Create Account</h2>

<form action="register" method="post">
    <label>First Name:</label><br/>
    <input type="text" name="firstname" required /><br/><br/>

    <label>Username:</label><br/>
    <input type="text" name="username" required /><br/><br/>

    <label>Password:</label><br/>
    <input type="password" name="password" required /><br/><br/>

    <button type="submit">Create Account</button>
</form>

<br/>

<a href="login.jsp">Back to Login</a>

</body>
</html>