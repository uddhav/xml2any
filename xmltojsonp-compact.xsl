<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!-- Output: JSONP -->
	<xsl:output method="text" omit-xml-declaration="yes" version="1.0" encoding="UTF-8"/>
	
	<!-- Strip whitespace -->
    <xsl:strip-space elements="*"/>
    
    <!-- Are decimals supported by the JS interpreter  -->
    <xsl:param name="decimalSupported">yes</xsl:param>
    <xsl:param name="callback">callback</xsl:param>
    
    <!-- Naming a JS variable -->
    <xsl:template name="variable-name">
    	<xsl:param name="name" />
    	
    	<xsl:value-of select="translate($name, ':', '_')" />
    </xsl:template>
    
    <!-- Lower case -->
    <xsl:template name="lower-case">
    	<xsl:param name="text" />
    	
    	<xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
		<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
    	
    	<xsl:choose>
			<xsl:when test="contains($text, '.')">
				<xsl:value-of select="translate(substring-after($text, '.'), $uppercase, $smallcase)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="translate($text, $uppercase, $smallcase)"/>
			</xsl:otherwise>
		</xsl:choose>
    </xsl:template>
    
    <!-- Top Element -->
    <xsl:variable name="topElement">
    	<xsl:variable name="temp">
	    	<xsl:call-template name="variable-name">
	    		<xsl:with-param name="name" select="name(/*)" />
	    	</xsl:call-template>
	    </xsl:variable>
	    
	    <xsl:call-template name="lower-case">
    		<xsl:with-param name="text" select="$temp" />
    	</xsl:call-template>
    </xsl:variable>
    
    <!-- "local result={...}; return result;" idiom -->
    <xsl:template match="/">
    	<xsl:choose>
    		<xsl:when test="$callback != ''">
    			<xsl:value-of select="$callback" />
    		</xsl:when>
    		<xsl:otherwise>
    			<xsl:text>callback</xsl:text>
    		</xsl:otherwise>
    	</xsl:choose>
    	<!-- "local " -->
    	<xsl:text>({</xsl:text>
    	
    	<!-- Parse all XML -->
  		<xsl:apply-templates select="*"/>
  		
  		<!-- ";return {};" -->
   		<xsl:text>})</xsl:text>
   	</xsl:template>
   	
   	<!-- Count all attributes that we parse -->
   	<xsl:template name="count-attributes">		
		<xsl:for-each select="@*">
			<xsl:if test="contains(name(), ':')">
				<xsl:value-of select="position()" />
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
   	
   	<!-- Loop through all attributes -->
   	<xsl:template match="@*">		
		<xsl:if test="position() > 1">
			<!-- Comma -->
			<xsl:text>,</xsl:text>
		</xsl:if>
		
		<xsl:if test="not(contains(name(), ':'))">
			<xsl:text>"</xsl:text>
			<xsl:value-of select="name()"/>
			<xsl:text>":</xsl:text>
			<xsl:call-template name="print-value">
				<xsl:with-param name="value" select="." />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
    
    <!-- Loop through all nodes -->
	<xsl:template match="*">		
		<!-- Count -->
		<xsl:variable name="count">
			<xsl:value-of select="count(parent::*/*[name(current())=name()])"/>
		</xsl:variable>
		
		<!-- Count -->
		<xsl:variable name="qname">
			<xsl:value-of select="name()"/>
		</xsl:variable>
		
		<!-- Local tag name -->
		<xsl:variable name="parentTag">
			<xsl:call-template name="variable-name">
    			<xsl:with-param name="name" select="$qname" />
    		</xsl:call-template>
		</xsl:variable>
		
		<!-- Difference between topmost list tag and topmost sibling -->
		<xsl:variable name="difference">
			<xsl:variable name="temp">
				<xsl:for-each select="../*">
					<xsl:if test="$qname=name() and ($count > 1 or *)">
						<xsl:value-of select="position()"/>
						<xsl:text>,</xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			
			<xsl:value-of select="number(substring-before($temp, ','))"/>
		</xsl:variable>
		
		<!-- Lower case the tag -->
		<xsl:variable name="tag">
			<xsl:call-template name="lower-case">
	    		<xsl:with-param name="text" select="$parentTag" />
	    	</xsl:call-template>
		</xsl:variable>
		
		<!-- Index of the element in list -->
		<xsl:variable name="index">
			<xsl:choose>
				<xsl:when test="string($difference)!='NaN'">
					<xsl:value-of select="position() - $difference + 1"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="position()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- Suffix -->
		<xsl:variable name="suffix">
			<xsl:if test="$count > 1 or contains(local-name(), '.') or (* and name() != name(/*))">
				<xsl:text>u</xsl:text>
			</xsl:if>
		</xsl:variable>
		
		<!-- Comma for all positions after 1st. -->
		<xsl:if test="position() > 1">
			<xsl:text>,</xsl:text>
		</xsl:if>
		
		<!-- Test if Node has children -->
		<xsl:choose>
			<!-- Has children -->
			<xsl:when test="*">
				<xsl:if test="$index = 1">
					<!-- Tag -->
					<xsl:text>"</xsl:text>
					<xsl:value-of select="$tag"/>
					<xsl:text>":</xsl:text>
					<xsl:choose>
						<xsl:when test="$suffix!=''">
							<xsl:text>[</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>{</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!-- If suffix then declare table first -->
				<xsl:if test="$suffix!=''">
					<xsl:text>{</xsl:text>
				</xsl:if>
				
				<!-- Go to attributes -->
				<xsl:if test="@*">
					<xsl:apply-templates select="@*" />
					
					<xsl:variable name="countAttribs">
						<xsl:call-template name="count-attributes" />
					</xsl:variable>
					
					<xsl:if test="$countAttribs=''">
						<xsl:text>,</xsl:text>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<!-- No children -->
			<xsl:otherwise>
				<!-- If suffix then declare table first -->
				<xsl:if test="$suffix!='' and $index = 1">
					<xsl:text>"</xsl:text>
					<xsl:value-of select="$tag"/>
					<xsl:text>":[</xsl:text>
				</xsl:if>
				
				<!-- No Suffix so declare variable -->
				<xsl:if test="$suffix=''">
					<xsl:text>"</xsl:text>
					<xsl:value-of select="$tag"/>
					<xsl:text>":</xsl:text>
				</xsl:if>
				
				<!-- If attributes present, declare table -->
				<xsl:if test="@*">
					<xsl:text>{</xsl:text>
				</xsl:if>
				
				<!-- Go to attributes -->
				<xsl:apply-templates select="@*" />
				
				<!-- If attributes present, publish content as value -->
				<xsl:if test="@*">
					<xsl:text>,"value"</xsl:text>
					<xsl:text>:</xsl:text>
				</xsl:if>
				
				<!-- Print value -->
				<xsl:call-template name="print-value">
					<xsl:with-param name="value" select="." />
				</xsl:call-template>	
				
				<!-- If attribs -->
				<xsl:if test="@*">
					<xsl:text>}</xsl:text>
				</xsl:if>			
			</xsl:otherwise>
		</xsl:choose>
		
		<!-- Go to child -->
		<xsl:apply-templates select="*" />
		
		<!-- Close table created by suffix conditions -->
		<xsl:if test="$suffix!='' and $index=count(../*[name()=name(current())])">
			<xsl:choose>
				<xsl:when test="*">
					<xsl:text>}</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>]</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		
		<!-- Close table -->
		<xsl:if test="*">
			<xsl:choose>
				<xsl:when test="$suffix!='' and $index=count(../*[name()=name(current())])">
					<xsl:text>]</xsl:text>		
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>}</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<!-- Prints -->
	<xsl:template name="print-value">
		<xsl:param name="value" />
		
		<!-- Test if value is number -->
		<xsl:choose>
			<!-- Not number -->
			<xsl:when test="string(number($value))='NaN' or ($decimalSupported!='yes' and contains($value, '.'))">
				<xsl:text>"</xsl:text>
				<xsl:call-template name="lua-encode">
					<xsl:with-param name="text" select="$value"/>
				</xsl:call-template>
				<xsl:text>"</xsl:text>
			</xsl:when>
			<!-- Is number -->
			<xsl:otherwise>
				<xsl:value-of select="$value"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Taken from http://geekswithblogs.net/Erik/archive/2008/04/01/120915.aspx -->
	<xsl:template name="string-replace-all">
		<xsl:param name="text" />
		<xsl:param name="replace" />
		<xsl:param name="by" />
		    
		<xsl:choose>
			<xsl:when test="contains($text, $replace)">
				<xsl:value-of select="substring-before($text,$replace)" />
				<xsl:value-of select="$by" />
				<xsl:call-template name="string-replace-all">
					<xsl:with-param name="text" select="substring-after($text,$replace)" />
					<xsl:with-param name="replace" select="$replace" />
					<xsl:with-param name="by" select="$by" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="lua-encode">
		<xsl:param name="text" />
		
		<xsl:variable name="backslash">\</xsl:variable>
		<xsl:variable name="quote">"</xsl:variable>
		<xsl:variable name="apos">'</xsl:variable>
		<xsl:variable name="lsqb">[</xsl:variable>
		<xsl:variable name="rsqb">]</xsl:variable>
		
		<!-- Backslash -->
		<xsl:variable name="var1">
			<xsl:call-template name="string-replace-all">
				<xsl:with-param name="text" select="$text" />
				<xsl:with-param name="replace" select="$backslash" />
				<xsl:with-param name="by" select="concat($backslash, $backslash)" />
			</xsl:call-template>
		</xsl:variable>
		
		<!-- Quote -->
		<xsl:variable name="var2">
			<xsl:call-template name="string-replace-all">
				<xsl:with-param name="text" select="$var1" />
				<xsl:with-param name="replace" select="$quote" />
				<xsl:with-param name="by" select="concat($backslash, $quote)" />
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:value-of select="normalize-space($var2)" />
	</xsl:template>
</xsl:stylesheet>
