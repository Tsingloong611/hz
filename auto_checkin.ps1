# �����Ҫ�ĳ���
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# ����user32.dll��ʹ��SetForegroundWindow����
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@

# ������������
$yourName = "test"

# ���� UIAutomation ����
$uiAutomation = [System.Windows.Automation.AutomationElement]

# �ȴ������ҵ��ӵ�������
while ($true) {
    $window = $uiAutomation::RootElement.FindFirst(
        [System.Windows.Automation.TreeScope]::Children,
        [System.Windows.Automation.PropertyCondition]::new($uiAutomation::NameProperty, "���ӵ���")
    )
    
    if ($window) {
        Write-Host "�ҵ����ӵ�������"
        break
    }
    
    Start-Sleep -Seconds 1
}

# �۽�����
try {
    $windowHandle = [System.IntPtr]$window.Current.NativeWindowHandle
    [User32]::SetForegroundWindow($windowHandle) | Out-Null
    Write-Host "�Ѿ۽����ӵ�������"
    Start-Sleep -Milliseconds 500  # ������һЩʱ������Ӧ
} catch {
    Write-Host "�۽�����ʱ��������: $_"
}

# ���Ҳ���д���������
$nameInput = $window.FindFirst(
    [System.Windows.Automation.TreeScope]::Descendants,
    [System.Windows.Automation.PropertyCondition]::new($uiAutomation::AutomationIdProperty, "1730")
)

if ($nameInput) {
    try {
        $pattern = [System.Windows.Automation.ValuePattern]::Pattern
        $valuePattern = $nameInput.GetCurrentPattern($pattern)
        if ($valuePattern) {
            $valuePattern.SetValue($yourName)
            Write-Host "����д����"
        } else {
            # �����ȡ ValuePattern ʧ�ܣ�����ʹ�� SendKeys
            [System.Windows.Forms.SendKeys]::SendWait($yourName)
            Write-Host "ʹ�� SendKeys ��д����"
        }
    } catch {
        Write-Host "��д����ʱ��������: $_"
        # ʹ�� SendKeys ��Ϊ��ѡ����
        [System.Windows.Forms.SendKeys]::SendWait($yourName)
        Write-Host "ʹ�� SendKeys ��д����"
    }
} else {
    Write-Host "δ�ҵ����������"
}

function ClickOkButton {
    $okButton = $window.FindFirst(
        [System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.PropertyCondition]::new($uiAutomation::NameProperty, "Ok")
    )

    if (-not $okButton) {
        # ���û�ҵ� "Ok"�����Բ��� "ȷ��" ��ť
        $okButton = $window.FindFirst(
            [System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.PropertyCondition]::new($uiAutomation::NameProperty, "ȷ��")
        )
    }

        # �۽�����
    try {
        $windowHandle = [System.IntPtr]$window.Current.NativeWindowHandle
        [User32]::SetForegroundWindow($windowHandle) | Out-Null
        Write-Host "�Ѿ۽����ӵ�������"
        Start-Sleep -Milliseconds 500  # ������һЩʱ������Ӧ
    } catch {
        Write-Host "�۽�����ʱ��������: $_"
    }

    if ($okButton) {
        try {
            # ����ʹ�� InvokePattern
            $pattern = [System.Windows.Automation.InvokePattern]::Pattern
            $invokePattern = $okButton.GetCurrentPattern($pattern)
            if ($invokePattern) {
                $invokePattern.Invoke()
                Write-Host "��ʹ�� InvokePattern ���ȷ����ť"
                return $true
            }
        } catch {
            Write-Host "ʹ�� InvokePattern �����ťʧ��: $_"
        }

        try {
            # ����ʹ�� Click ����
            $okButton.Click()
            Write-Host "��ʹ�� Click �������ȷ����ť"
            return $true
        } catch {
            Write-Host "ʹ�� Click ���������ťʧ��: $_"
        }

        try {
            # ����ģ�������
            $buttonRect = $okButton.Current.BoundingRectangle
            $x = $buttonRect.Left + $buttonRect.Width / 2
            $y = $buttonRect.Top + $buttonRect.Height / 2
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            PerformMouseClick $buttonX $buttonY
            Write-Host "��ģ�������ȷ����ť"
            return $true
        } catch {
            Write-Host "ģ���������ťʧ��: $_"
        }
    } else {
        Write-Host "δ�ҵ�ȷ����ť"
    }

    return $false
}

# ���Ե��ȷ����ť�����ʧ��������
$maxAttempts = 3
$attemptCount = 0
$success = $false

while (-not $success -and $attemptCount -lt $maxAttempts) {
    $attemptCount++
    Write-Host "���Ե��ȷ����ť���� $attemptCount ��"
    $success = ClickOkButton
    if (-not $success) {
        Start-Sleep -Seconds 1
    }
}

if ($success) {
    Write-Host "�ɹ����ȷ����ť"
} else {
    Write-Host "�޷����ȷ����ť�����ֶ���ɲ���"
}

Write-Host "�ű�ִ�����"