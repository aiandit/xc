<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:param name="template-doc-uri" select="'/main/getf/templates/html/offer.html'"/>
  <xsl:param name="template-doc" select="document($template-doc-uri)"/>

  <xsl:variable name="this" select="/"/>

  <xsl:include href="view-utils.xsl"/>

  <xsl:template match="/">
    <div>
      <xsl:if test="not($template-doc)">
        <div>
          <p>
            <span style="color: red;"> Failed to load template document <xsl:value-of select="$template-doc-uri"/> </span>
          </p>
        </div>
        <xsl:message> Failed to load template document <xsl:value-of select="$template-doc-uri"/>
        </xsl:message>
      </xsl:if>
      <xsl:apply-templates select="$template-doc/*/xhtml:body/*"/>
    </div>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='tradeitems-headline']">
    <tr>
      <td></td>
      <th class="aleft">Posten</th>
      <th class="aright">
        Anzahl
      </th>
      <th class="aright">
        Preis
      </th>
      <th class="aright">
        Gesamt
      </th>
    </tr>
  </xsl:template>

  <xsl:template match="*" mode="as-price">
    <span class="price">
      <span class="number">
        <xsl:value-of select="format-number(., '0.00')"/>
      </span>
      <xsl:value-of select="../x:cur|../../x:cur"/>
    </span>
  </xsl:template>

  <xsl:template match="*" mode="as-number">
    <span class="number">
      <xsl:value-of select="number(.)"/>
    </span>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='tradeitems']">
    <xsl:for-each select="$this/*/x:cont/x:offer/x:calculation/x:tradeitem">
      <tr>
        <td class="aleft" style="width:1.8em;">
          <xsl:number format="0"/>.
        </td>
        <td>
          <xsl:value-of select="x:desc"/>
        </td>
        <td class="aright ntd">
          <xsl:apply-templates select="x:amount" mode="as-number"/>
        </td>
        <td class="aright ntd">
          <xsl:apply-templates select="x:price" mode="as-price"/>
        </td>
        <td class="aright ntd">
          <xsl:apply-templates select="x:cost" mode="as-price"/>
        </td>
      </tr>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='sum-netto']">
    <tr>
      <td>
      </td>
      <td>
        Netto
      </td>
      <td>
      </td>
      <td>
      </td>
      <td class="aright">
        <xsl:apply-templates select="$this/*/x:cont/x:offer/x:calculation/x:sum-netto" mode="as-price"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='sum-taxes']">
    <tr>
      <td>
      </td>
      <td>USt. <xsl:value-of select="$this/*/x:cont/x:offer/x:calculation/x:uststz*100"/>%</td>
      <td>
      </td>
      <td>
      </td>
      <td class="aright">
        <xsl:apply-templates select="$this/*/x:cont/x:offer/x:calculation/x:sum-taxes" mode="as-price"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='sum-brutto']">
    <tr>
      <td>
      </td>
      <th class="aleft">
        Brutto
      </th>
      <td>
      </td>
      <td>
      </td>
      <td class="aright">
        <b>
          <xsl:apply-templates select="$this/*/x:cont/x:offer/x:calculation/x:sum-brutto" mode="as-price"/>
        </b>
      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>
