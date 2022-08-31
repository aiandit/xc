<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="/">
    <div>
      <h4>XC Default Config View</h4>
      <p>
        This will normally be overwritten by your content, when you
        create your own <a
        href="/main/getf?path=xsl/config-view-html.xsl">config-view-html.xsl</a>
        and/or <a
        href="/main/getf?path=pipelines/config-view-html.xml">config-view-html.xml</a>.
      </p>
      <ul>
        <xsl:apply-templates/>
      </ul>
    </div>
  </xsl:template>

  <xsl:template match="*">
    <li>
      <div>
        <h4><xsl:value-of select="name()"/></h4>
        <ul>
          <xsl:apply-templates/>
        </ul>
      </div>
    </li>
  </xsl:template>


  <xsl:template match="x:code-repo" mode="link">
    <a href="{.}" class="xc-nocatch"><xsl:value-of select="."/></a>
  </xsl:template>
  
  <xsl:template match="x:get-help">
    <div>
      The XC source code can be found at <xsl:apply-templates select="x:code-repo" mode="link"/>.
    </div>
  </xsl:template>

</xsl:stylesheet>
