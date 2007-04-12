<%@ page
	language="java" 
	contentType="text/html" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.jcr.nodetype.*,javax.naming.InitialContext,java.io.*, java.util.*,java.net.URLEncoder"
%>

<%/*
 * [madhatter] Codejive CMS package
 * 
 * Copyright (C) 2006 Tako Schotanus
 * 
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 * 
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this library; see the file COPYING.  If not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA.
 * 
 * Linking this library statically or dynamically with other modules is
 * making a combined work based on this library.  Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * As a special exception, the copyright holders of this library give you
 * permission to link this library with independent modules to produce an
 * executable, regardless of the license terms of these independent
 * modules, and to copy and distribute the resulting executable under
 * terms of your choice, provided that you also meet, for each linked
 * independent module, the terms and conditions of the license of that
 * module.  An independent module is a module which is not derived from
 * or based on this library.  If you modify this library, you may extend
 * this exception to your version of the library, but you are not
 * obligated to do so.  If you do not wish to do so, delete this
 * exception statement from your version.
 * 
*/%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=<%= response.getCharacterEncoding() %>">
	<title>Repo Dump</title>
	<style>
		.info {
			border-width : 1;
			border-style : solid;
			margin-bottom : 4px;
		}
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
%>

	<div class="info">
		<a href="types.jsp">Types</a>
		<a href="namespaces.jsp">Namespaces</a>
	</div>
	
	<div class="info">
		Show properties:
		<%
			showYesNo(out, getURL(request, !showProperties, showSystem), showProperties);
		%>
		<br/>
		Show system nodes:
		<%
			showYesNo(out, getURL(request, showProperties, !showSystem), showSystem);
		%>
	</div>
	
<%
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
            if (canAddChildren(node)) {
	            out.print(" <a class=addlink href=\"resource.jsp?action=add&parentpath=" + node.getPath().substring(1) + "\">addChild</a>");
            }
            // Write an edit and delete link to all nodes except the root
            if (!node.getPath().equals("/")) {
                String typeName = node.getPrimaryNodeType().getName();
                if ("nt:resource".equals(typeName) || "mad:content".equals(typeName)) {
	                out.print(" <a class=viewlink href=\"retrieve?uuid=" + node.getUUID() + "\">view</a>");
                }
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

	private static boolean canAddChildren(Node node) throws RepositoryException {
	    boolean canAdd = canAddChildren(node, node.getPrimaryNodeType());
	    for (int i = 0; !canAdd && (i < node.getMixinNodeTypes().length); i++) {
	        NodeType nodeType = node.getMixinNodeTypes()[i];
	        canAdd = canAddChildren(node, nodeType);
	    }
	    return canAdd;
	}

	private static boolean canAddChildren(Node node, NodeType nodeType) throws RepositoryException {
	    boolean canAdd = false;
	    for (int i = 0; !canAdd && (i < nodeType.getChildNodeDefinitions().length); i++) {
	        NodeDefinition def = nodeType.getChildNodeDefinitions()[i];
	        if (def.getName().equals("*") || def.allowsSameNameSiblings()) {
	            // Multiple children are allowed
	            canAdd = true;
	        } else {
	            // Named child, check if it already exists
	            if (!def.isMandatory()) {
	                canAdd = (node.getNode(def.getName()) == null);
	            }
	        }
	    }
	    return canAdd;
	}

	private String getValue(String value, String defaultValue) {
	    return (value != null) ? value : defaultValue;
	}
	
	private String getURL(HttpServletRequest request, boolean showProperties, boolean showSystem) throws UnsupportedEncodingException {
	    String url = "";
	    
	    HashMap<String, String> params = new HashMap<String, String>();
	    Enumeration e = request.getParameterNames();
	    while (e.hasMoreElements()) {
	        String name = (String) e.nextElement();
	        String value = request.getParameter(name);
	        params.put(name, value);
	    }
	    
	    params.put("properties", Boolean.toString(showProperties));
	    params.put("system", Boolean.toString(showSystem));
	    
	    for (String name : params.keySet()) {
	        String value = params.get(name);
	        if (url.length() == 0) {
	            url += "?";
	        } else {
	            url += "&";
	        }
	        url += name + "=" + URLEncoder.encode(value, "UTF-8");
	    }
	    url = "dump.jsp" + url;
	    return url;
	}
	
	private void showYesNo(JspWriter out, String url, boolean value) throws IOException {
	    String val = (value) ? "Yes" : "No";
	    out.println("<a href=\"" + url + "\">" + val + "</a>");
	}
%>
