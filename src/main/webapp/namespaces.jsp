<%@ page
	language="java" 
	contentType="text/html" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.naming.InitialContext,java.io.*,java.util.*"
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

<%

String action = request.getParameter("action");
if (action == null || action.length() == 0) {
    action = "add";
}

boolean isNew = "add".equals(action);

String prefix = getValue(request.getParameter("prefix"), "");
String uri = getValue(request.getParameter("uri"), "");
String selectedPrefix = request.getParameter("selected");

InitialContext context = new InitialContext();
Repository repository = (Repository) context.lookup("jcr/repository");
Session repSession = repository.login(new SimpleCredentials("username", "password".toCharArray()));
NamespaceRegistry nsreg = repSession.getWorkspace().getNamespaceRegistry();

if (request.getParameter("submitted") != null) {
    if ("delete".equals(action) || "update".equals(action)) {
        nsreg.unregisterNamespace(prefix);
    }
    if ("add".equals(action) || "update".equals(action)) {
        nsreg.registerNamespace(prefix, uri);
    }
	response.sendRedirect("namespaces.jsp?selected=" + prefix);
} else {
    if (prefix.length() > 0 && uri.length() == 0) {
	    uri = nsreg.getURI(prefix);
    } else if (prefix.length() == 0 && uri.length() > 0) {
	    prefix = nsreg.getPrefix(uri);
    }
}

String buttonName;
if ("add".equals(action)) {
    buttonName = "Add";
} else if ("update".equals(action)) {
    buttonName = "Update";
} else if ("delete".equals(action)) {
    buttonName = "Delete";
} else {
    buttonName = "???";
}

request.setAttribute("action", action);
request.setAttribute("prefix", prefix);
request.setAttribute("uri", uri);
request.setAttribute("selectedPrefix", selectedPrefix);
request.setAttribute("buttonName", buttonName);

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=<%= response.getCharacterEncoding() %>">
	<title>Namespaces</title>
	<style>
		.info {
			border-width : 1;
			border-style : solid;
			margin-bottom : 4px;
		}
		.nstable {
			border-width : 1;
			border-style : solid;
		}
		.selected {
			background-color : red;
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
		TR.selected .nsprefix {
			font-weight : bold;
			color : white;
		}
		TR.selected .defaultprefix {
			color : white;
		}
		TR.selected .nsuri {
			color : yellow;
		}
	</style>
</head>
<body>

	<div class="info">
		<a href="dump.jsp">Repository</a>
		<a href="types.jsp">Types</a>
	</div>
	
<form method="post" action="namespaces.jsp">
	<table>
		<tr>
			<td>Prefix</td>
			<td>
				<% if (isNew) { %>
				<input type="text" name="prefix" value="${prefix}">
				<% } else { %>
				${prefix}
				<input type="hidden" name="prefix" value="${prefix}">
				<% } %>
			</td>
		</tr>
		<tr>
			<td>URI</td>
			<td><input type="text" name="uri" value="${uri}" size="60"></td>
		</tr>
	</table>
	<input type="hidden" name="action" value="${action}">
	<input type="submit" name="submitted" value="${buttonName}">
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
	dump(out, nsreg, selectedPrefix);
%>
</table>

</body>
</html>

<%!
    private static void dump(JspWriter out, NamespaceRegistry nsreg, String selectedPrefix) throws RepositoryException, IOException {
    	String[] prefixes = nsreg.getPrefixes();
    	Arrays.sort(prefixes);
    	for (String prefix : prefixes) {
    	    String uri = nsreg.getURI(prefix);
    	    
            // Output the namespace info
            if (prefix.equals(selectedPrefix)) {
	            out.print("<tr class=selected>");
            } else {
	            out.print("<tr>");
            }
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
