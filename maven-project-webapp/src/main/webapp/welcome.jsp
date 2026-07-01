<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
</head>
<body>

<%
    String name = (String) request.getAttribute("name");
    if (name == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<h2>Welcome to Project Zeus, <%= name %></h2>

<br/>

<a href="login.jsp">Logout</a>

</body>
</html>