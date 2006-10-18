<%@ page
	language="java" 
	contentType="text/html" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.naming.InitialContext,java.io.*"
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=<%= response.getCharacterEncoding() %>">
	<title>Repo Dump</title>
	<style>
		.nodepath {
			font-weight : bold;
		}
		.nodetype {
			color : green;
		}
	</style>
</head>
<body>

<%
	InitialContext context = new InitialContext();
	Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
	Session repSession = repository.login(new SimpleCredentials("username", "password".toCharArray()));
	boolean showProperties = "true".equals(getValue(request.getParameter("properties"), "false"));
	boolean showSystem = "true".equals(getValue(request.getParameter("system"), "false"));
	dump(out, repSession.getRootNode(), showProperties, showSystem);
%>

</body>
</html>

<%!
	/** Recursively outputs the contents of the given node. */
    private static void dump(JspWriter out, Node node, boolean showProperties, boolean showSystem) throws RepositoryException, IOException {
        // First output an anchor
        out.print("<a name=\"" + node.getPath() + "\">");

        // Second output the node path text
        out.print("<span class=nodepath>" + node.getPath() + "</span>");
        
        // third output the node´s primary type
        String primaryType = node.getProperty("jcr:primaryType").getString();
        out.print(" <span class=nodetype>[" + primaryType + "]</span>");
        
        // Write action links for all nodes except the jcr:system subtree
        if (showSystem || !node.getName().equals("jcr:system")) {
            // Write an "add child" link
            if (node.getPrimaryNodeType().getChildNodeDefinitions().length > 0) {
	            out.print(" <a class=addlink href=\"resource.jsp?action=add&parentpath=" + node.getPath().substring(1) + "\">addChild</a>");
            }
            // Write an edit and delete link to all nodes except the root
            if (!node.getPath().equals("/")) {
                out.print(" <a class=editlink href=\"resource.jsp?action=update&path=" + node.getPath().substring(1) + "\">edit</a>");
                if (node.getParent().getPrimaryNodeType().canRemoveItem(node.getName())) {
	                out.print(" <a class=deletelink href=\"resource.jsp?action=delete&path=" + node.getPath().substring(1) + "\">delete</a>");
                }
            }
        }
        out.println("<br>");

        if (showProperties) {
	        // Then output the properties
	        PropertyIterator properties = node.getProperties();
	        while (properties.hasNext()) {
	            Property property = properties.nextProperty();
	            if (property.getDefinition().isMultiple()) {
	                // A multi-valued property, print all values
	                Value[] values = property.getValues();
	                for (int i = 0; i < values.length; i++) {
	                    out.println("<span class=property><span class=propertyname>" + property.getPath() + "</span> = <span class=propertyvalue>" + values[i].getString() + "</span></span><br>");
	                }
	            } else {
	                // A single-valued property
	                out.println("<span class=property><span class=propertyname>" + property.getPath() + "</span> = <span class=propertyvalue>" + property.getString() + "</span></span><br>");
	            }
	        }
	        out.println("<br>");
        }

        // Skip the virtual (and large!) jcr:system subtree
        if (showSystem || !node.getName().equals("jcr:system")) {
            // Finally output all the child nodes recursively
            NodeIterator nodes = node.getNodes();
            while (nodes.hasNext()) {
                dump(out, nodes.nextNode(), showProperties, showSystem);
            }
        }
    }

	private String getValue(String value, String defaultValue) {
	    return (value != null) ? value : defaultValue;
	}
%>
