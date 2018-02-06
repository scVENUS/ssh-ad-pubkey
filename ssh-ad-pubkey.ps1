<#
   .SYNOPSIS
      Manage Ssh Public Key in Active Directory.
   
   .DESCRIPTION
      Add or remove the SSH Public Key central stored in Active Directory. 
      The SSH Public Key can be in a File or Console Input.
      Listing of the SSH Public Key in a file or in Active Directory for an User 
      Further the AD can be checked for the desired AD schema extentions.
   
   .NOTES
      You need the permission to change the SSH Public Key in AD.
      

   .EXAMPLE
      PS C:\>ssh-ad-pubkey -list
     
      List the SSH Public Key(s) for the current user.
      
   
   .EXAMPLE        
      PS C:\>ssh-ad-pubkey -list anna
     
      PS C:\>ssh-ad-pubkey -list -sam  anna    
     
      PS C:\>ssh-ad-pubkey -list -user anna

      List the SSH Public Key(s) for the user with SamAccountName Anna.

   .EXAMPLE
         
      PS C:\>ssh-ad-pubkey -list -filepath C:\Users\anna\.ssh\id_ed25519.pub

      List the SSH Public Key in File
   
   .EXAMPLE   

      PS C:\>ssh-ad-pubkey -add -filepath C:\Users\anna\.ssh\id_ed25519.pub 
      
      Add SSH Public Key in File to AD for current user
      
      PS C:\>ssh-ad-pubkey -add -filepath C:\common\id_ed25519.pub -sam otto

      Add SSH Public Key in File to AD for user otto

   .EXAMPLE         
          
      PS C:\>ssh-ad-pubkey -add -sshpubkey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/GnZYLGmAoC95 anna@workshop@windev1" 

      Add SSH Public Key from Console to AD for current user 
      
      PS C:\>ssh-ad-pubkey -add -sshpubkey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgixWPrskbEG42 otto@workshop@windev1"  -sam otto  

      Add SSH Public Key from Console to AD for user otto

   .EXAMPLE 
     
      PS C:\>ssh-ad-pubkey -remove -filepath C:\Users\anna\.ssh\id_ed25519.pub
      
      Remove SSH Public Key in File from AD for current user 
      
      PS C:\>ssh-ad-pubkey -remove -filepath C:\common\id_ed25519.pub -sam otto 
         
      Remove SSH Public Key in File from AD for user otto
      
   .EXAMPLE 
      
      PS C:\>ssh-ad-pubkey -remove -sshpubkey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/GnZYLGmAoC95 anna@workshop@windev1" 
      
      Remove SSH Public Key from Console from AD for current user
     
      PS C:\>ssh-ad-pubkey -remove -sshpubkey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgixWPrskbEG42 otto@workshop@windev1" -sam otto

      Remove SSH Public Key from Console from AD for user otto

   .EXAMPLE 
      PS C:\>ssh-ad-pubkey -clear

      Clear all SSH Public Keys from AD for current user

      PS C:\>ssh-ad-pubkey -clear -sam otto 

      Clear all SSH Public Key from AD for user otto
      
  .EXAMPLE    
      
     PS C:\> ssh-add-pubkey -check

     Check the AD schema for the required extentions for OpenSSH

  .EXAMPLE

     PS c:\> import-csv .\userlist.csv -Delimiter ',' | % {.\ssh-ad-pubkey.ps1 -list:$true $_.sam}

     List the SSH Public Key stored in Active Directory from all Users defined in a comma separated file. 


#>

[CmdletBinding(DefaultParameterSetName = 'noaction')]
Param( 
      [Parameter(ParameterSetName='listfromfile', Mandatory=$true,position=0)]
      [Parameter(ParameterSetName='listad', Mandatory=$true, position=0)] 
      [switch] $list,
       

      [Parameter(ParameterSetName='addstring', Mandatory=$true,position=0)]
      [Parameter(ParameterSetName='addfromfile', Mandatory=$true,position=0)]
      [switch] $add,
      
      [Parameter(ParameterSetName='removestring', Mandatory=$true,position=0)]
      [Parameter(ParameterSetName='removefromfile', Mandatory=$true,position=0)]
      [switch] $remove,

      [Parameter(ParameterSetName='clear', Mandatory=$true,position=0)]
      [switch] $clear,

      [Parameter(ParameterSetName='check', Mandatory=$true,position=0)]
      [switch] $check,


      [Parameter(ParameterSetName='listfromfile', Mandatory=$true)]
      [Parameter(ParameterSetName='addfromfile', Mandatory=$true,position=1)]
      [Parameter(ParameterSetName='removefromfile', Mandatory=$true,position=1)]
      [ValidateNotNullOrEmpty()]
      [string] $filepath,

      [Parameter(ParameterSetName='addstring', Mandatory=$true,position=1)]
      [Parameter(ParameterSetName='removestring', Mandatory=$true,position=1)]
      [ValidateNotNullOrEmpty()]
      [string] $sshpubkey,
       
      [Parameter(ParameterSetName='listad', Mandatory= $false, position=1)]
      [Parameter(ParameterSetName='clear', Mandatory= $false, position=1)]
      [Parameter(ParameterSetName='addfromfile', Mandatory=$false,position=2)]
      [Parameter(ParameterSetName='removefromfile', Mandatory=$false,position=2)]
      [Parameter(ParameterSetName='addstring', Mandatory=$false,position=2)]
      [Parameter(ParameterSetName='removestring', Mandatory=$false,position=2)]
      [alias("user")]
      [ValidateNotNullOrEmpty()]
      [String]$sam
      
)


Set-StrictMode -Version 2.0

[string] $action = "list"
if ($add)
{
   $action = "add"
}
elseif ($list)
{
   $action =  "list"   
}
elseif ($remove)
{
   $action = "remove"
}
elseif ($check)
{
   $action = "check"
}
elseif ($clear)
{
   $action = "clear"
}
else
{
  write-host "Please use ssh-ad-pubkey one of the following switches:`n-add -list -remove -clear -check`n"
  & $MyInvocation.MyCommand.Definition -?
  exit
}




# Load the Assemblies for DirectoryServices
# Unfortunately Active Directory Module is currently 
# not working with PowerShell Core 6.x 
# Find-Module -Name PSCoreWindowsCompat
# Install-Module -Name PSCoreWindowsCompat -Repository PSGallery -Verbose -Force
 
if  ($PSVersionTable.PSEdition -eq "Core")
{
   Import-Module PSCoreWindowsCompat
}
else
{
    Add-Type -AssemblyName "System.DirectoryServices.AccountManagement"
}


function find-ADProperty
{
  Param(
  [ValidateNotNullOrEmpty()]
  [string] $PropertyName
  )

  $found = $false
  try
  {
    $RootDSE = [System.DirectoryServices.DirectoryEntry]([System.DirectoryServices.DirectoryEntry]"LDAP://RootDSE")
  
    # Retrieve the Schema naming context, the distinguished name of the Schema container in AD.
    $schemaNC = $rootDSE.Properties["schemaNamingContext"][0]
 
    # Create DirectorySearcher object
    $ADSearcher = New-Object DirectoryServices.DirectorySearcher
    # Filter on the LDAPDisplayName attribute
    $ADSearcher.Filter = "(&(LDAPDisplayName=$PropertyName))"
    # Search in the Schema
    $ADSearcher.SearchRoot = "LDAP://$schemaNC"
    # Return only one result
    $schemaObj = $ADSearcher.FindOne()
    if ($schemaObj)
    {      
      $found = $true
    }
  }
  catch 
  {
    $ErrorMessage = $_.Exception.Message
    Write-Warning "Something goes wrong"
    Write-Warning "$ErrorMessage"  
    $found = $false
  }
  return $found
}

function find-CustomObjectinUser
{
  
  $found = $false
  try
  {
    $RootDSE = [System.DirectoryServices.DirectoryEntry]([System.DirectoryServices.DirectoryEntry]"LDAP://RootDSE")
  
    # Retrieve the Schema naming context, the distinguished name of the Schema container in AD.
    $schemaNC = $rootDSE.Properties["schemaNamingContext"][0]
    # Create DirectorySearcher object
    $ADSearcher = New-Object DirectoryServices.DirectorySearcher
    # Filter on the LDAPDisplayName attribute
    $ADSearcher.Filter = "(&(LDAPDisplayName=user))"
    # Search in the Schema
    $ADSearcher.SearchRoot = "LDAP://$schemaNC"
    # Return only one result
    $schemaObj = $ADSearcher.FindOne()
    if ($schemaObj)
    {            
      $found = (($schemaObj).Properties.auxiliaryclass)-contains "ldappublickey"
    }
  }
  catch 
  {
    $ErrorMessage = $_.Exception.Message
    Write-Warning "Something goes wrong"
    Write-Warning "$ErrorMessage" 
    $found = $false
  }
  return $found
}


function test-CustomizedSchema
{
 
  $a = find-ADProperty "sshPublicKey"
  $b = find-ADProperty "ldapPublicKey"
  $c = find-CustomObjectinUser  

    if ( $a -and $b -and $c)
    {
      write-Host "Customized AD Schema is OK!"
    }
    else
    {
       write-Host "Missing AD Schema Extensions!"
       if (!$a) 
       {
          "Attribute sshPublicKey is missing!"
       }
       if (!$b)
       {
          "Class ldapPublicKey is missing!" 
       }
       if (!$c)
       {
         "Auxillary class ldapPublicKey is not in user object!"
       }
    } 
}



function show-ADSSHPublicKey
{
  Param([System.DirectoryServices.AccountManagement.UserPrincipal] $u)
  try
  {
    $k = ($u.GetUnderlyingObject()).Properties
    [bool] $x = $k.Contains("SShPublicKey")

    # Entry exists
    if ($x)
    {
       $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False 
       $k = ($u.GetUnderlyingObject()).Properties.sshPublicKey
       $n = $k.count
       write-host "$($u.samAccountName) has $n SSH Public Key(s) in AD:"
      
          
       for ($i=0; $i -lt $n ; $i++)
       {
          write-host "$($Utf8NoBomEncoding.GetString($k[$i]))"
       }            
    }
    else
    {
       write-host "$($u.samAccountName) has no SSH Public Key in AD!!!"
    }
    write-host
  }
  Catch [System.UnauthorizedAccessException] 
  {
    $ErrorMessage = $_.Exception.Message
    Write-Warning "No Access to Object $u"
    Write-Warning "$ErrorMessage"    

  }
  catch
  {     
    $ErrorMessage = $_.Exception.Message
    Write-Warning "Something goes wrong"
    Write-Warning "$ErrorMessage"  
  }

}

function get-ADSSHPublicKey
{
  Param([System.DirectoryServices.AccountManagement.UserPrincipal] $u)
  try
  {
    $k = ($u.GetUnderlyingObject()).Properties
    [bool] $x = $k.Contains("SShPublicKey")
    $s = New-Object System.Collections.Generic.List[String]
    # Entry exists
    if ($x)
    {
       $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False 
       $k = ($u.GetUnderlyingObject()).Properties.sshPublicKey
       $n = $k.count
          
       for ($i=0; $i -lt $n ; $i++)
       {
          $s.add($Utf8NoBomEncoding.GetString($k[$i]))
       }  
    }
    else
    {
       $s= $null
    }
    return $s
        
  }
  Catch [System.UnauthorizedAccessException] 
  {
    $ErrorMessage = $_.Exception.Message
    Write-Warning "No Access to Object $u"
    Write-Warning "$ErrorMessage"    

  }
  catch
  {     
    $ErrorMessage = $_.Exception.Message
    Write-Warning "Something goes wrong"
    Write-Warning "$ErrorMessage"  
  }

}


function get-FileSSHPublicKey
{
  Param(  [ValidateNotNullOrEmpty()] 
          [string] $sshpkpath)
  $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
  try 
  {
    if([System.IO.File]::Exists($sshpkpath))
    {
      $f = [System.IO.File]::ReadAllLines($sshpkpath, $Utf8NoBomEncoding)
      return $f 
    }
    else
    {
       write-warning "Path/file $sshpkpath not found !!!"
       return $null
    }
  }
  Catch [System.UnauthorizedAccessException] 
  {
    $ErrorMessage = $_.Exception.Message
    Write-Warning "No Access to Object $sshpkpath"
    Write-Warning "$ErrorMessage"    
  }
  catch
  {     
    $ErrorMessage = $_.Exception.Message
    Write-Warning "Something goes wrong"
    Write-Warning "$ErrorMessage"  
  }
}

function show-FileSSHPublicKey
{
  Param( [ValidateNotNullOrEmpty()]
         [string] $sshpkpath)
  
  $f = get-FileSSHPublicKey $sshpkpath
  if ($f)
  {
    write-Host "Contents of $sshpkpath"
    write-host "$f"
  }
}

function update-ADSSHPublicKey
{
  Param([System.DirectoryServices.AccountManagement.UserPrincipal] $u,
        [ValidateNotNullOrEmpty()]
        [string] $sshpk,
        [ValidateSet("add","remove")]
        [string] $act)
   $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False 
   [byte[]] $octets = $Utf8NoBomEncoding.GetBytes($sshpk)
   try
   {   
     if ($act -eq "add")
     { 
       ($u.GetUnderlyingObject()).Properties["sshpublickey"].Add($octets) | Out-Null 
     }
     else 
     {
       ($u.GetUnderlyingObject()).Properties["sshpublickey"].Remove($octets) 
     }
     
     $u.Save()
   }
   Catch [System.UnauthorizedAccessException] 
   {
      $ErrorMessage = $_.Exception.Message
      Write-Warning "No Access to Object $($u.samaccountname)"
      Write-Warning "$ErrorMessage" 
   }
   catch
   {
      $ErrorMessage = $_.Exception.Message
      Write-Warning "Something goes wrong"
      Write-Warning "$ErrorMessage"  
   }
    
}


function clear-ADSSHPublicKey
{
  Param([System.DirectoryServices.AccountManagement.UserPrincipal] $u)
        
   try
   {   
     ($u.GetUnderlyingObject()).Properties["sshpublickey"].Clear()
     $u.Save()
   }
   Catch [System.UnauthorizedAccessException] 
   {
      $ErrorMessage = $_.Exception.Message
      Write-Warning "No Access to Object $($u.samaccountname)"
      Write-Warning "$ErrorMessage" 
   }
   catch
   {
      $ErrorMessage = $_.Exception.Message
      Write-Warning "Something goes wrong"
      Write-Warning "$ErrorMessage"  
   }
    
}


function get-UserFromAD
{
   [System.DirectoryServices.AccountManagement.UserPrincipal] $user = $null
   try
   {
     if (!$sam)
     {
       $sam = ([System.DirectoryServices.AccountManagement.UserPrincipal]::Current).samaccountname
     }
   
     $ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
     $Context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ContextType
     $user = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($Context,$sam)  
   }
   catch
   {
      $ErrorMessage = $_.Exception.Message
      Write-Warning "Something goes wrong"
      Write-Warning "$ErrorMessage" 
      $user = $null
   }
   return $user
 }


function show-sshkeys
{
  if ($filepath) 
  { 
     show-FileSSHPublicKey $filepath
  } 
  else 
  {
     $user = get-UserFromAD
    
     if ($user)
     {
        show-ADSSHPublicKey $user
     }
     else
     {
       write-warning "User $sam not found in AD"
     }   
  }
}


function update-sshkey
{
   $err = $false
   # first get ssh keys from file or console 
   if ($filepath) 
   { 
     $f=get-FileSSHPublicKey $filepath
     if (!$f) 
     {
        $err=$true     
     }
  }
  elseif ($sshpubkey)
  {
    $f = $sshpubkey.Trim()
    if ([string]::IsNullOrEmpty($f))
    {
        $err=$true 
    }
  }
  else
  {
   $err =$true
  }
  # 2. Step 
  # Get User
  if (!$err)
  { 
     $user = get-UserFromAD
     if ($user)
     {
        update-ADSSHPublicKey $user $f $action
     }
     else
     {
        write-warning "User $sam not found in AD"       
     }
     
  }

}

function remove-sshkeys
{
   # Get User 
   $user = get-UserFromAD
   if ($user)
   {
      clear-ADSSHPublicKey $user
   }
   else
   {
      write-warning "User $sam not found in AD"       
   }
}



# Main

switch ($action)
{
  "list"      { show-sshkeys}                       
  "add"       { update-sshkey}
  "remove"    { update-sshkey}
  "clear"     { remove-sshkeys}
  "check"     { test-CustomizedSchema }
}