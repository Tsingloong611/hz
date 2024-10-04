# 导入必要的程序集
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# 导入user32.dll以使用SetForegroundWindow函数
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@

# 设置您的姓名
$yourName = "test"

# 创建 UIAutomation 对象
$uiAutomation = [System.Windows.Automation.AutomationElement]

# 等待并查找电子点名窗口
while ($true) {
    $window = $uiAutomation::RootElement.FindFirst(
        [System.Windows.Automation.TreeScope]::Children,
        [System.Windows.Automation.PropertyCondition]::new($uiAutomation::NameProperty, "电子点名")
    )
    
    if ($window) {
        Write-Host "找到电子点名窗口"
        break
    }
    
    Start-Sleep -Seconds 1
}

# 聚焦窗口
try {
    $windowHandle = [System.IntPtr]$window.Current.NativeWindowHandle
    [User32]::SetForegroundWindow($windowHandle) | Out-Null
    Write-Host "已聚焦电子点名窗口"
    Start-Sleep -Milliseconds 500  # 给窗口一些时间来响应
} catch {
    Write-Host "聚焦窗口时发生错误: $_"
}

# 查找并填写姓名输入框
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
            Write-Host "已填写姓名"
        } else {
            # 如果获取 ValuePattern 失败，尝试使用 SendKeys
            [System.Windows.Forms.SendKeys]::SendWait($yourName)
            Write-Host "使用 SendKeys 填写姓名"
        }
    } catch {
        Write-Host "填写姓名时发生错误: $_"
        # 使用 SendKeys 作为备选方法
        [System.Windows.Forms.SendKeys]::SendWait($yourName)
        Write-Host "使用 SendKeys 填写姓名"
    }
} else {
    Write-Host "未找到姓名输入框"
}

function ClickOkButton {
    $okButton = $window.FindFirst(
        [System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.PropertyCondition]::new($uiAutomation::NameProperty, "Ok")
    )

    if (-not $okButton) {
        # 如果没找到 "Ok"，尝试查找 "确定" 按钮
        $okButton = $window.FindFirst(
            [System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.PropertyCondition]::new($uiAutomation::NameProperty, "确定")
        )
    }

        # 聚焦窗口
    try {
        $windowHandle = [System.IntPtr]$window.Current.NativeWindowHandle
        [User32]::SetForegroundWindow($windowHandle) | Out-Null
        Write-Host "已聚焦电子点名窗口"
        Start-Sleep -Milliseconds 500  # 给窗口一些时间来响应
    } catch {
        Write-Host "聚焦窗口时发生错误: $_"
    }

    if ($okButton) {
        try {
            # 尝试使用 InvokePattern
            $pattern = [System.Windows.Automation.InvokePattern]::Pattern
            $invokePattern = $okButton.GetCurrentPattern($pattern)
            if ($invokePattern) {
                $invokePattern.Invoke()
                Write-Host "已使用 InvokePattern 点击确定按钮"
                return $true
            }
        } catch {
            Write-Host "使用 InvokePattern 点击按钮失败: $_"
        }

        try {
            # 尝试使用 Click 方法
            $okButton.Click()
            Write-Host "已使用 Click 方法点击确定按钮"
            return $true
        } catch {
            Write-Host "使用 Click 方法点击按钮失败: $_"
        }

        try {
            # 尝试模拟鼠标点击
            $buttonRect = $okButton.Current.BoundingRectangle
            $x = $buttonRect.Left + $buttonRect.Width / 2
            $y = $buttonRect.Top + $buttonRect.Height / 2
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            PerformMouseClick $buttonX $buttonY
            Write-Host "已模拟鼠标点击确定按钮"
            return $true
        } catch {
            Write-Host "模拟鼠标点击按钮失败: $_"
        }
    } else {
        Write-Host "未找到确定按钮"
    }

    return $false
}

# 尝试点击确定按钮，如果失败则重试
$maxAttempts = 3
$attemptCount = 0
$success = $false

while (-not $success -and $attemptCount -lt $maxAttempts) {
    $attemptCount++
    Write-Host "尝试点击确定按钮，第 $attemptCount 次"
    $success = ClickOkButton
    if (-not $success) {
        Start-Sleep -Seconds 1
    }
}

if ($success) {
    Write-Host "成功点击确定按钮"
} else {
    Write-Host "无法点击确定按钮，请手动完成操作"
}

Write-Host "脚本执行完毕"