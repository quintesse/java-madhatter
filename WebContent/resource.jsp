<%@ page
	language="java" 
	contentType="text/html; charset=UTF-8" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.naming.*,java.io.*,java.util.Calendar"
%>

<%

//request.setCharacterEncoding("UTF-8");

String action = request.getParameter("action");
if (action == null || action.length() == 0) {
    action = "add";
}

boolean isNew = "add".equals(action);

String uuid = getValue(request.getParameter("uuid"), "");
String path = getValue(request.getParameter("path"), "");
String mimeType = getValue(request.getParameter("mimetype"), "text/plain");
String encoding = getValue(request.getParameter("encoding"), "UTF-8");
String data = getValue(request.getParameter("data"), "");
Calendar modified = null;

if (request.getParameter("submitted") != null) {
	modified = Calendar.getInstance();
	Session repSession = getSession();
	Node root = repSession.getRootNode();
	Node node;
	if (isNew) {
		node = root.addNode(path, "nt:resource");
	} else {
        node = root.getNode(path);
	}
	node.setProperty("jcr:mimeType", mimeType);
	node.setProperty("jcr:encoding", encoding);
	node.setProperty("jcr:data", data);
	node.setProperty("jcr:lastModified", modified);
	repSession.save();
	uuid = node.getUUID();
	response.sendRedirect("resource.jsp?action=update&uuid=" + uuid);
} else {
    if (path.length() > 0 || uuid.length() > 0) {
    	Session repSession = getSession();
    	Node node = null;
        if (uuid != null && uuid.length() > 0) {
            node = repSession.getNodeByUUID(uuid);
        } else if (path != null && path.length() > 0) {
            Node root = repSession.getRootNode();
            node = root.getNode(path);
        }
        if (node != null) {
	        uuid = node.getProperty("jcr:uuid").getString();
	        path = node.getPath().substring(1);
	        mimeType = node.getProperty("jcr:mimeType").getString();
	        encoding = node.getProperty("jcr:encoding").getString();
	        data = node.getProperty("jcr:data").getString();
	    	modified = node.getProperty("jcr:lastModified").getDate();
        } else {
            isNew = true;
            action = "add";
        }
    }
}

String buttonName = (isNew) ? "Add" : "Update";

request.setAttribute("uuid", uuid);
request.setAttribute("path", path);
request.setAttribute("mimeType", mimeType);
request.setAttribute("encoding", encoding);
request.setAttribute("data", data);
request.setAttribute("modified", modified);
request.setAttribute("buttonName", buttonName);

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= response.getCharacterEncoding() %>">
<title>Repo Resource Manager</title>
</head>
<body>
	<form method="post" accept-charset="UTF-8">
		<table>
			<%
			if (!isNew) { 
			%>
			<tr>
				<td>UUID</td>
				<td>${uuid}</td>
			</tr>
			<% } %>
			<tr>
				<td>Path</td>
				<td><input type="text" name="path" value="${path}"></td>
			</tr>
			<tr>
				<td>Content type</td>
				<td><input type="text" name="mimetype" value="${mimeType}"></td>
			</tr>
			<tr>
				<td>Content encoding</td>
				<td><input type="text" name="encoding" value="${encoding}"></td>
			</tr>
			<tr>
				<td>Data</td>
				<td><textarea name="data" cols="80" rows="20">${data}</textarea></td>
			</tr>
			<%
			if (modified != null) { 
			%>
			<tr>
				<td>Lastmodified</td>
				<td>${modified.time}</td>
			</tr>
			<% } %>
		</table>
		<input type="hidden" name="action" value="${action}">
		<input type="submit" name="submitted" value="${buttonName}">
	</form>
	
</body>
</html>

<%!

private Session getSession() throws NamingException, RepositoryException {
	InitialContext context = new InitialContext();
	Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
	Session session = repository.login(new SimpleCredentials("username", "password".toCharArray()));
	return session;
}

private String getValue(String value, String defaultValue) {
    return (value != null) ? value : defaultValue;
}

%>

