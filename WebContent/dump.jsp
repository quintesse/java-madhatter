<%@ page
	language="java" 
	contentType="text/html; 
	charset=UTF-8" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.naming.InitialContext,java.io.*"
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Repo Dump</title>
</head>
<body>

<pre>
<%
	InitialContext context = new InitialContext();
	Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
	Session repSession = repository.login(new SimpleCredentials("username", "password".toCharArray()));
	dump(out, repSession.getRootNode());
%>
</pre>

</body>
</html>

<%!
    /** Recursively outputs the contents of the given node. */
    private static void dump(JspWriter out, Node node) throws RepositoryException, IOException {
        // First output the node path
        out.println(node.getPath());
        // Skip the virtual (and large!) jcr:system subtree
        if (node.getName().equals("jcr:system")) {
            return;
        }

        // Then output the properties
        PropertyIterator properties = node.getProperties();
        while (properties.hasNext()) {
            Property property = properties.nextProperty();
            if (property.getDefinition().isMultiple()) {
                // A multi-valued property, print all values
                Value[] values = property.getValues();
                for (int i = 0; i < values.length; i++) {
                    out.println(property.getPath() + " = " + values[i].getString());
                }
            } else {
                // A single-valued property
                out.println(property.getPath() + " = " + property.getString());
            }
        }

        // Finally output all the child nodes recursively
        NodeIterator nodes = node.getNodes();
        while (nodes.hasNext()) {
            dump(out, nodes.nextNode());
        }
    }
%>
