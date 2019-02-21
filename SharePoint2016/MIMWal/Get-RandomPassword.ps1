function Generate-RandomPassword
{
	Param
	(
		[parameter(Mandatory=$false)]
		$length = 12	
	)
	return ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort {Get-Random})[0..$length] -join "";$Password.Replace("&","5")
}

$initialPassword = Generate-RandomPassword -length 12
$initialPassword