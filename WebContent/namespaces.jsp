<%@ page
	language="java" 
	contentType="text/html" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.naming.InitialContext,java.io.*,java.util.*"
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=<%= response.getCharacterEncoding() %>">
	<title>Namespaces</title>
	<style>
		.nstable {
			border-width : 1;
			border-style : solid;
		}
		.nsprefix {
			font-weight : bold;
		}
		.defaultprefix {
			color : gray;
		}
		.nsuri {
			color : green;
		}
	</style>
</head>
<body>

<form method="post" action="namesapces.jsp">
	<table>
		<tr>
			<td>Prefix</td>
			<td><input type="text" name="prefix" value="${prefix}"></td>
		</tr>
		<tr>
			<td>URI</td>
			<td><input type="text" name="uri" value="${uri}"></td>
		</tr>
	</table>
	<input type="hidden" name="action" value="${action}">
	<input type="submit" name="submitted" value="${submitbutton}">
</form>

<p>

<table class=nstable>
<thead>
	<tr>
		<th>Prefix</th>
		<th>URI</th>
		<th>Action</th>
	</tr>
</thead>
<%
	InitialContext context = new InitialContext();
	Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
	Session repSession = repository.login(new SimpleCredentials("username", "password".toCharArray()));
	dump(out, repSession.getWorkspace().getNamespaceRegistry());
%>
</table>

</body>
</html>

<%!
    private static void dump(JspWriter out, NamespaceRegistry nsreg) throws RepositoryException, IOException {
    	String[] prefixes = nsreg.getPrefixes();
    	Arrays.sort(prefixes);
    	for (String prefix : prefixes) {
    	    String uri = nsreg.getURI(prefix);
    	    
            // Output the namespace info
            out.print("<tr>");
            if (prefix.length() > 0) {
	            out.print("<td><span class=nsprefix>" + prefix + "</span></td>");
            } else {
	            out.print("<td><span class=defaultprefix>&lt;default&gt;</span></td>");
            }
            out.print("<td><span class=nsuri>" + uri + "</span></td>");
            
            // Write action links for namespaces
            out.print("<td>");
            if (prefix.length() > 0 && !" jcr nt mix sv xml ".contains(" " + prefix + " ")) {
	            out.print(" <a class=editlink href=\"namespaces.jsp?action=update&prefix=" + prefix + "\">edit</a>");
	            out.print(" <a class=deletelink href=\"namespaces.jsp?action=delete&prefix=" + prefix + "\">delete</a>");
            }
            out.print("</td>");
            out.print("</tr>");
    	}
    }

	private String getValue(String value, String defaultValue) {
	    return (value != null) ? value : defaultValue;
	}
%>
