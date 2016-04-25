<?php

class PouetToTxt
{
    protected $page = 0;
    const URL_LASTPRODS = 'http://www.pouet.net/export/lastprodsreleased.rss.php?platform=ZX%20Enhanced&type=demo&howmany=100';
    const URL_PRODEXP = 'http://www.pouet.net/export/prod.xnfo.php?which=';
    const ELEMENTS_ONPAGE = 10;

    /**
     * @param mixed $page
     */
    public function setPage($page)
    {
        if ($page < 0 || $page > 9) {
            $this->page = 0;
        } else {
            $this->page = $page;
        }
    }

    /**
     * @param mixed $rssUrl
     */
    public function setRssUrl($rssUrl)
    {
        $this->rssUrl = $rssUrl;
    }

    public function getTxt()
    {
        $text = "\r\n";
        if ($data = $this->parseRss()) {
            $text = $this->makeTxt($data);
        }
        return $text;
    }

    protected function makeTxt($data)
    {
        $text = '';
        foreach ($data as $item) {
            $text .= $item['title'] . "\n";
            $text .= $item['link'] . "\n";
            $text .= $item['year'] . "\n";
            $text .= $item['author'] . "\n";
            $text .= $item['country'] . "\n";
        }
        $text .= "\r\n";
        return $text;
    }

    protected function parseRss()
    {
        $result = [];
        if ($content = file_get_contents(self::URL_LASTPRODS)) {
            if ($xml = simplexml_load_string($content)) {
                $start = $this->page * self::ELEMENTS_ONPAGE;
                $counter = 0;

                foreach ($xml->channel->item as $node) {
                    if ($counter >= $start && $counter < $start + self::ELEMENTS_ONPAGE) {
                        if ($prodInfo = $this->getProdInfo($node, $counter)) {
                            $result[] = $prodInfo;
                        }
                    }
                    $counter++;

                }
            }
        }
        return $result;
    }

    protected function getProdInfo($node, $number = 0)
    {
        $info = false;
        if ($id = $this->parseId((string)$node->link)) {
            if ($content = file_get_contents(self::URL_PRODEXP . $id)) {
                if ($xml = simplexml_load_string($content)) {
                    if (isset($xml->demo)) {
                        $info = [
                            'title'   => ($number + 1) . '.',
                            'link'    => '',
                            'year'    => '',
                            'author'  => '',
                            'country' => '',
                        ];
                        if (isset($xml->demo->name)) {
                            $info['title'] .= (string)$xml->demo->name;
                        }
                        if (isset($xml->demo->releaseDate)) {
                            $info['year'] = date('Y', strtotime($xml->demo->releaseDate));
                        }
                        if (isset($xml->demo->download)) {
                            foreach ($xml->demo->download->children() as $childNode) {
                                $attributes = $childNode->attributes();
                                if (isset($attributes['type']) && strtolower($attributes['type']) == 'download') {
                                    $info['link'] = (string)$childNode;
                                    break;
                                }
                            }
                        }
                        if (isset($xml->demo->authors)) {
                            $authors = [];
                            foreach ($xml->demo->authors->children() as $childNode) {
                                $authors[] = (string)$childNode;
                            }
                            $info['author'] = implode(', ', $authors);
                        }
                        if (isset($xml->demo->release) && isset($xml->demo->release->party)) {
                            $info['country'] = (string)$xml->demo->release->party;
                        }
                    }
                }
            }
        }
        return $info;
    }

    protected function parseId($link)
    {
        $parse = parse_url($link);
        parse_str($parse['query'], $parameters);
        if (isset($parameters['which'])) {
            return (int)$parameters['which'];
        }
        return false;
    }
}

if (isset($_GET['p']) && $_GET['p']) {
    $page = (int)$_GET['p'] - 1;
} else {
    $page = 0;
}

$pouetToTxt = new PouetToTxt();
$pouetToTxt->setPage($page);
header('Content-type: text/plain');
echo $pouetToTxt->getTxt();
