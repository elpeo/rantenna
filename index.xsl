<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:rss="http://purl.org/rss/1.0/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:content="http://purl.org/rss/1.0/modules/content/" 
	exclude-result-prefixes="rdf rss dc"
>

<xsl:output encoding="EUC-JP" method="xml"
	doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
	doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
/>

<!-- root -->
<xsl:template match="/">
  <xsl:apply-templates select="rdf:RDF"/>
</xsl:template>

<!-- html body -->
<xsl:template match="rdf:RDF">
  <html lang="ja-JP">
	  <xsl:apply-templates select="rss:channel"/>
	  <body>
		 <h1><xsl:value-of select="rss:channel/rss:title"/></h1>
	  <div class="day">
		<h2>
		  <span class="date">
		  <xsl:value-of select="translate(substring(rss:channel/dc:date,1,19),'T-',' /')"/>
		  <xsl:text> update.</xsl:text>
		  </span>
		</h2>
	  	<div class="body">
		  <ol>
			<xsl:apply-templates select="rss:item"/>
		  </ol>
	  	</div>
	  </div>
	  <hr class="sep"/>
	  <div class="footer">
	  <xsl:value-of select="rss:channel/dc:publisher"/><br/>
	  <xsl:value-of select="rss:channel/dc:rights"/>
	  </div>
	  </body>
	</html>
</xsl:template>

<!-- html head -->
<xsl:template match="rss:channel">
	<head>
	<title><xsl:value-of select="rss:title"/></title>
	<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP" />
	<meta http-equiv="content-style-type" content="text/css" />
	<link rel="alternate" type="application/rss+xml" title="RSS">
	  <xsl:attribute name="href">
		 <xsl:value-of select="@rdf:about"/>
	  </xsl:attribute>
	</link>
	<link rel="stylesheet" href="theme/base.css" type="text/css" media="all" />
	<link rel="stylesheet" href="theme/rantenna/rantenna.css" title="rantenna" type="text/css" media="all"/>
	</head>
</xsl:template>

<!-- entry -->
<xsl:template match="rss:item">
	<li>
		<xsl:choose>
			<xsl:when test="dc:date">
				<xsl:value-of select="translate(substring(dc:date,1,19),'T-',' /')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>----/--/-- --:--:--</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> </xsl:text>
		<a>
		  <xsl:attribute name="href">
			 <xsl:value-of select="rss:link"/>
		  </xsl:attribute>
		  <xsl:value-of select="rss:title"/>
		</a>
		<xsl:text> </xsl:text>
		<xsl:value-of select="dc:creator"/>
		<br />
	</li>
</xsl:template>

</xsl:stylesheet>
